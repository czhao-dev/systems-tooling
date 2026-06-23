#include "buildlab/core.h"

#include <ctype.h>
#include <string.h>

static int is_ascii_space(char c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' || c == '\v';
}

int buildlab_is_blank(const char *str) {
    if (str == NULL) {
        return 1;
    }
    for (; *str != '\0'; ++str) {
        if (!is_ascii_space(*str)) {
            return 0;
        }
    }
    return 1;
}

char *buildlab_trim(char *str) {
    if (str == NULL) {
        return NULL;
    }

    char *start = str;
    while (*start != '\0' && is_ascii_space(*start)) {
        ++start;
    }

    size_t len = strlen(start);
    while (len > 0 && is_ascii_space(start[len - 1])) {
        --len;
    }
    start[len] = '\0';

    if (start != str) {
        memmove(str, start, len + 1);
    }
    return str;
}

size_t buildlab_count_occurrences(const char *haystack, const char *needle) {
    if (haystack == NULL || needle == NULL || *needle == '\0') {
        return 0;
    }

    size_t count = 0;
    size_t needle_len = strlen(needle);
    const char *cursor = haystack;
    while ((cursor = strstr(cursor, needle)) != NULL) {
        ++count;
        cursor += needle_len;
    }
    return count;
}

long buildlab_clamp_long(long value, long lo, long hi) {
    if (value < lo) {
        return lo;
    }
    if (value > hi) {
        return hi;
    }
    return value;
}

const char *buildlab_core_version(void) { return "0.1.0"; }
