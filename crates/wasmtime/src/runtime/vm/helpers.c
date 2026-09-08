#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef CFG_TARGET_OS_macos
#include <dlfcn.h>
#include <pthread.h>
#endif

#define CONCAT2(a, b) a##b
#define CONCAT(a, b) CONCAT2(a, b)
#define VERSIONED_SYMBOL(a) CONCAT(a, VERSIONED_SUFFIX)

#ifdef FEATURE_DEBUG_BUILTINS
#ifdef CFG_TARGET_OS_windows
#define DEBUG_BUILTIN_EXPORT __declspec(dllexport)
#else
#define DEBUG_BUILTIN_EXPORT
#endif

// This set of symbols is defined here in C because Rust's #[export_name]
// functions are not dllexported on Windows when building an executable. These
// symbols are directly referenced by name from the native DWARF info.
void *VERSIONED_SYMBOL(resolve_vmctx_memory_ptr)(void *);
DEBUG_BUILTIN_EXPORT void *
VERSIONED_SYMBOL(wasmtime_resolve_vmctx_memory_ptr)(void *p) {
  return VERSIONED_SYMBOL(resolve_vmctx_memory_ptr)(p);
}
void VERSIONED_SYMBOL(set_vmctx_memory)(void *);
DEBUG_BUILTIN_EXPORT void VERSIONED_SYMBOL(wasmtime_set_vmctx_memory)(void *p) {
  VERSIONED_SYMBOL(set_vmctx_memory)(p);
}

// Helper symbol called from Rust to force the above two functions to not get
// stripped by the linker.
void VERSIONED_SYMBOL(wasmtime_debug_builtins_init)() {
#ifndef CFG_TARGET_OS_windows
  void *volatile p;
  p = (void *)&VERSIONED_SYMBOL(wasmtime_resolve_vmctx_memory_ptr);
  p = (void *)&VERSIONED_SYMBOL(wasmtime_set_vmctx_memory);
  (void)p;
#endif
}
#endif // FEATURE_DEBUG_BUILTINS

// For more information about this see `unix/unwind.rs` and the
// `using_libunwind` function. The basic idea is that weak symbols aren't stable
// in Rust so we use a bit of C to work around that.
#ifndef CFG_TARGET_OS_windows
__attribute__((weak)) extern void __unw_add_dynamic_fde();

bool VERSIONED_SYMBOL(wasmtime_using_libunwind)() {
  return __unw_add_dynamic_fde != NULL;
}

#ifdef CFG_TARGET_OS_macos
// Even weak imports must be present in the SDK's link stubs on macOS. Look
// these optional APIs up at runtime so older SDKs can still build Wasmtime.
// Cache the pair: registration may happen concurrently on multiple threads.
typedef void (*unwind_section_fn)(uintptr_t);
static unwind_section_fn add_eh_frame_section;
static unwind_section_fn remove_eh_frame_section;
static pthread_once_t unwind_section_once = PTHREAD_ONCE_INIT;

static void load_unwind_section_api(void) {
  // Use the system unwinder, as with macOS's __register_frame import. Keep the
  // handle open for the lifetime of the cached function pointers.
  void *lib = dlopen("/usr/lib/system/libunwind.dylib", RTLD_LAZY | RTLD_LOCAL);
  if (lib == NULL)
    return;
  add_eh_frame_section = (unwind_section_fn)dlsym(
      lib, "__unw_add_dynamic_eh_frame_section");
  remove_eh_frame_section = (unwind_section_fn)dlsym(
      lib, "__unw_remove_dynamic_eh_frame_section");
}
#else
__attribute__((weak)) extern void
__unw_add_dynamic_eh_frame_section(uintptr_t);
__attribute__((weak)) extern void
__unw_remove_dynamic_eh_frame_section(uintptr_t);
#define add_eh_frame_section __unw_add_dynamic_eh_frame_section
#define remove_eh_frame_section __unw_remove_dynamic_eh_frame_section
#endif

// Older libunwind versions do not provide these entry points. Require the
// matched pair before registering so that teardown uses the same grouping.
bool VERSIONED_SYMBOL(wasmtime_register_eh_frame_section)(const uint8_t *section) {
#ifdef CFG_TARGET_OS_macos
  pthread_once(&unwind_section_once, load_unwind_section_api);
#endif
  if (add_eh_frame_section == NULL || remove_eh_frame_section == NULL) {
    return false;
  }
  add_eh_frame_section((uintptr_t)section);
  return true;
}

void VERSIONED_SYMBOL(wasmtime_deregister_eh_frame_section)(const uint8_t *section) {
  remove_eh_frame_section((uintptr_t)section);
}
#endif
