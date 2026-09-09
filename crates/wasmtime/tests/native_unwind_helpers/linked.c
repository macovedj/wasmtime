#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

extern bool wasmtime_register_eh_frame_section_test(const uint8_t *);
extern void wasmtime_deregister_eh_frame_section_test(const uint8_t *);
extern void check_registrations(int);

int main(void) {
  static const uint8_t section[] = {0, 0, 0, 0};
  for (int i = 0; i < 3; i++) {
    bool registered = wasmtime_register_eh_frame_section_test(section);
    assert(registered == (AVAILABLE == 3));
    if (registered)
      wasmtime_deregister_eh_frame_section_test(section);
    check_registrations(AVAILABLE == 3 ? i + 1 : 0);
  }
}
