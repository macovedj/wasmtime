// A linked provider with its own registration state, independent of the
// system unwinder. The linked fixture uses real dladdr/dlopen/dlsym calls.
#include <assert.h>
#include <stdint.h>

static int adds, removes;
static uintptr_t registered;

void __register_frame(const void *fde) { (void)fde; }
void __deregister_frame(const void *fde) { (void)fde; }

#if AVAILABLE & 1
void __unw_add_dynamic_eh_frame_section(uintptr_t section) {
  assert(registered == 0);
  registered = section;
  adds++;
}
#endif

#if AVAILABLE & 2
void __unw_remove_dynamic_eh_frame_section(uintptr_t section) {
  assert(registered == section);
  registered = 0;
  removes++;
}
#endif

void check_registrations(int expected) {
  assert(adds == expected);
  assert(removes == expected);
  assert(registered == 0);
}
