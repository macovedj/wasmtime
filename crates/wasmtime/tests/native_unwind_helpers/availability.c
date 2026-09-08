#include <assert.h>
#include <dlfcn.h>
#include <stdint.h>
#include <string.h>

static void *lookup(void *, const char *);
static void *open_library(const char *, int);
#define dlopen open_library
#define dlsym lookup
#define VERSIONED_SUFFIX _test
#include "../../src/runtime/vm/helpers.c"

static const uint8_t section[] = {0, 0, 0, 0};
static int opens, lookups, adds, removes;
static int library;

static void *open_library(const char *path, int mode) {
  assert(strcmp(path, "/usr/lib/system/libunwind.dylib") == 0);
  assert(mode == (RTLD_LAZY | RTLD_LOCAL));
  opens++;
  return PROVIDER_AVAILABLE ? &library : NULL;
}

#if AVAILABLE & 1
static void add(uintptr_t address) {
  assert(address == (uintptr_t)section);
  adds++;
}
#endif

#if AVAILABLE & 2
static void remove_section(uintptr_t address) {
  assert(address == (uintptr_t)section);
  removes++;
}
#endif

static void *lookup(void *handle, const char *name) {
  assert(handle == &library);
  lookups++;
  if (strcmp(name, "__unw_add_dynamic_eh_frame_section") == 0) {
#if AVAILABLE & 1
    return (void *)add;
#else
    return NULL;
#endif
  }
  assert(strcmp(name, "__unw_remove_dynamic_eh_frame_section") == 0);
#if AVAILABLE & 2
  return (void *)remove_section;
#else
  return NULL;
#endif
}

int main(void) {
  // Repeated registrations reuse the resolved pair, including an absent pair.
  for (int i = 0; i < 3; i++) {
    bool registered = wasmtime_register_eh_frame_section_test(section);
    assert(registered == (PROVIDER_AVAILABLE && AVAILABLE == 3));
    if (registered)
      wasmtime_deregister_eh_frame_section_test(section);
    assert(adds == (PROVIDER_AVAILABLE && AVAILABLE == 3 ? i + 1 : 0));
    assert(removes == adds);
    assert(opens == 1);
    assert(lookups == (PROVIDER_AVAILABLE ? 2 : 0));
  }
}
