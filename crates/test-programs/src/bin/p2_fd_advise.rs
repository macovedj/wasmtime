use wasip2::filesystem::preopens::get_directories;
use wasip2::filesystem::types::{Advice, Descriptor, DescriptorFlags, OpenFlags, PathFlags};

fn test_fd_advise(dir: &Descriptor) {
    // Create a file in the scratch directory.
    let file = dir
        .open_at(
            PathFlags::empty(),
            "file",
            OpenFlags::CREATE,
            DescriptorFlags::READ | DescriptorFlags::WRITE,
        )
        .expect("failed to open file");

    // Check file size
    let stat = file.stat().expect("failed to stat");
    assert_eq!(stat.size, 0, "file size should be 0");

    // WillNeed on an empty file advises a range starting at end of file,
    // which should succeed: the advice is only a hint.
    file.advise(0, 0, Advice::WillNeed)
        .expect("failed advise on empty file");

    // set_size it bigger
    file.set_size(100).expect("setting size");

    let stat = file.stat().expect("failed to stat 2");
    assert_eq!(stat.size, 100, "file size should be 100");

    // Advise the kernel
    file.advise(10, 50, Advice::Normal).expect("failed advise");

    // WillNeed at or past end of file should succeed for the same reason.
    file.advise(100, 0, Advice::WillNeed)
        .expect("failed advise at end of file");
    file.advise(200, 50, Advice::WillNeed)
        .expect("failed advise past end of file");

    // Advise shouldn't change size
    let stat = file.stat().expect("failed to stat 3");
    assert_eq!(stat.size, 100, "file size should be 100");

    drop(file);
    dir.unlink_file_at("file").expect("failed to unlink");
}

fn main() {
    let preopens = get_directories();
    let (dir, _name) = &preopens[0];

    // Run the tests.
    test_fd_advise(dir)
}
