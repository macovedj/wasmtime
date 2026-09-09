#include <assert.h>
#include <dlfcn.h>
#include <stdint.h>
#include <string.h>

static void *lookup(void *, const char *);
static void *open_library(const char *, int);
static int find_library(const void *, Dl_info *);
static int close_library(void *);
#define dlopen open_library
#define dlsym lookup
#define dladdr find_library
#define dlclose close_library
#define VERSIONED_SUFFIX _test
#include "../../src/runtime/vm/helpers.c"

static const uint8_t section[] = {0, 0, 0, 0};
enum { UNKNOWN, UNAVAILABLE, WRONG_REGISTER, WRONG_DEREGISTER, MATCHING };
static int addresses, opens, closes, lookups, adds, removes;
static int library;
static const char provider_path[] = "/test/linked/libunwind.dylib";

static int find_library(const void *address, Dl_info *info) {
  assert(address == (void *)__register_frame);
  addresses++;
  info->dli_fname = provider_path;
  return PROVIDER != UNKNOWN;
}

static void *open_library(const char *path, int mode) {
  assert(strcmp(path, provider_path) == 0);
  assert(mode == (RTLD_LAZY | RTLD_LOCAL | RTLD_FIRST));
  opens++;
  return PROVIDER == UNAVAILABLE ? NULL : &library;
}

static int close_library(void *handle) {
  assert(handle == &library);
  closes++;
  return 0;
}

static void wrong_frame(const void *address) { (void)address; }

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
  if (strcmp(name, "__register_frame") == 0)
    return PROVIDER == WRONG_REGISTER ? (void *)wrong_frame
                                      : (void *)__register_frame;
  if (strcmp(name, "__deregister_frame") == 0)
    return PROVIDER == WRONG_DEREGISTER ? (void *)wrong_frame
                                        : (void *)__deregister_frame;
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
  const bool expected = PROVIDER == MATCHING && AVAILABLE == 3;
  const int expected_lookups =
      PROVIDER == UNKNOWN || PROVIDER == UNAVAILABLE ? 0 :
      PROVIDER == WRONG_REGISTER ? 1 :
      PROVIDER == WRONG_DEREGISTER ? 2 : 4;
  // Repeated registrations reuse the resolved pair, including an absent pair.
  for (int i = 0; i < 3; i++) {
    bool registered = wasmtime_register_eh_frame_section_test(section);
    assert(registered == expected);
    if (registered)
      wasmtime_deregister_eh_frame_section_test(section);
    assert(adds == (expected ? i + 1 : 0));
    assert(removes == adds);
    assert(addresses == 1);
    assert(opens == (PROVIDER != UNKNOWN));
    assert(closes == (PROVIDER != UNKNOWN && PROVIDER != UNAVAILABLE && !expected));
    assert(lookups == expected_lookups);
  }
}
