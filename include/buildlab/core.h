#ifndef BUILDLAB_CORE_H
#define BUILDLAB_CORE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Returns 1 if str is NULL, empty, or all-whitespace; otherwise 0. */
int buildlab_is_blank(const char *str);

/* Trims leading/trailing ASCII whitespace from str in-place and returns
 * str. Returns NULL if str is NULL. */
char *buildlab_trim(char *str);

/* Counts non-overlapping occurrences of needle in haystack. Returns 0 if
 * either argument is NULL or needle is empty. */
size_t buildlab_count_occurrences(const char *haystack, const char *needle);

/* Clamps value into [lo, hi]. Behavior is undefined if lo > hi. */
long buildlab_clamp_long(long value, long lo, long hi);

/* Returns the buildlab_core semantic version string, e.g. "0.1.0". */
const char *buildlab_core_version(void);

#ifdef __cplusplus
}
#endif

#endif /* BUILDLAB_CORE_H */
