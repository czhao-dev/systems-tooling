#include "buildlab/core.h"

#include <cstring>
#include <vector>

#include <gtest/gtest.h>

namespace {

char *to_buffer(std::vector<char> &storage, const char *text) {
    storage.assign(text, text + std::strlen(text) + 1);
    return storage.data();
}

} // namespace

TEST(IsBlank, NullIsBlank) { EXPECT_EQ(buildlab_is_blank(nullptr), 1); }

TEST(IsBlank, EmptyIsBlank) { EXPECT_EQ(buildlab_is_blank(""), 1); }

TEST(IsBlank, WhitespaceOnlyIsBlank) { EXPECT_EQ(buildlab_is_blank("   \t\n  "), 1); }

TEST(IsBlank, NonBlankIsNotBlank) { EXPECT_EQ(buildlab_is_blank("  x "), 0); }

TEST(Trim, NullReturnsNull) { EXPECT_EQ(buildlab_trim(nullptr), nullptr); }

TEST(Trim, RemovesLeadingAndTrailingWhitespace) {
    std::vector<char> storage;
    char *buffer = to_buffer(storage, "  hello world  ");
    EXPECT_STREQ(buildlab_trim(buffer), "hello world");
}

TEST(Trim, AllWhitespaceBecomesEmpty) {
    std::vector<char> storage;
    char *buffer = to_buffer(storage, "   \t  ");
    EXPECT_STREQ(buildlab_trim(buffer), "");
}

TEST(Trim, AlreadyTrimmedIsUnchanged) {
    std::vector<char> storage;
    char *buffer = to_buffer(storage, "already-trimmed");
    EXPECT_STREQ(buildlab_trim(buffer), "already-trimmed");
}

TEST(Trim, PreservesInternalWhitespace) {
    std::vector<char> storage;
    char *buffer = to_buffer(storage, "  a  b  ");
    EXPECT_STREQ(buildlab_trim(buffer), "a  b");
}

TEST(CountOccurrences, NoMatches) { EXPECT_EQ(buildlab_count_occurrences("hello", "z"), 0u); }

TEST(CountOccurrences, NonOverlappingMatches) {
    EXPECT_EQ(buildlab_count_occurrences("aaaa", "aa"), 2u);
}

TEST(CountOccurrences, OverlappingPatternCountedNonOverlapping) {
    EXPECT_EQ(buildlab_count_occurrences("aaa", "aa"), 1u);
}

TEST(CountOccurrences, EmptyNeedleReturnsZero) {
    EXPECT_EQ(buildlab_count_occurrences("hello", ""), 0u);
}

TEST(CountOccurrences, NullArgumentsReturnZero) {
    EXPECT_EQ(buildlab_count_occurrences(nullptr, "a"), 0u);
    EXPECT_EQ(buildlab_count_occurrences("a", nullptr), 0u);
}

TEST(ClampLong, ValueWithinRangeUnchanged) { EXPECT_EQ(buildlab_clamp_long(5, 0, 10), 5); }

TEST(ClampLong, BelowLoClampsToLo) { EXPECT_EQ(buildlab_clamp_long(-5, 0, 10), 0); }

TEST(ClampLong, AboveHiClampsToHi) { EXPECT_EQ(buildlab_clamp_long(50, 0, 10), 10); }

TEST(ClampLong, BoundaryValuesUnchanged) {
    EXPECT_EQ(buildlab_clamp_long(0, 0, 10), 0);
    EXPECT_EQ(buildlab_clamp_long(10, 0, 10), 10);
}

TEST(CoreVersion, ReturnsNonEmptyString) {
    const char *version = buildlab_core_version();
    ASSERT_NE(version, nullptr);
    EXPECT_GT(std::strlen(version), 0u);
}
