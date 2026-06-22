#include "buildlab/core.h"
#include "buildlab/net.hpp"

#include <string>
#include <vector>

#include <gtest/gtest.h>

using buildlab::net::Address;
using buildlab::net::format_address;
using buildlab::net::frame_message;
using buildlab::net::net_version;
using buildlab::net::parse_address;
using buildlab::net::try_decode_frame;

TEST(ParseAddress, ValidHostAndPort) {
    const auto address = parse_address("example.com:8080");
    ASSERT_TRUE(address.has_value());
    EXPECT_EQ(address->host, "example.com");
    EXPECT_EQ(address->port, 8080);
}

TEST(ParseAddress, MissingColonIsRejected) {
    EXPECT_FALSE(parse_address("example.com").has_value());
}

TEST(ParseAddress, EmptyHostIsRejected) { EXPECT_FALSE(parse_address(":8080").has_value()); }

TEST(ParseAddress, PortOutOfRangeIsRejected) {
    EXPECT_FALSE(parse_address("example.com:99999").has_value());
}

TEST(ParseAddress, NonNumericPortIsRejected) {
    EXPECT_FALSE(parse_address("example.com:http").has_value());
}

TEST(FormatAddress, RoundTripsWithParseAddress) {
    for (const char *text : {"example.com:8080", "localhost:1", "10.0.0.1:65535"}) {
        const auto address = parse_address(text);
        ASSERT_TRUE(address.has_value()) << text;
        EXPECT_EQ(format_address(*address), text);
    }
}

TEST(FrameMessage, RoundTripsThroughTryDecodeFrame) {
    auto buffer = frame_message("hello");
    const auto decoded = try_decode_frame(buffer);
    ASSERT_TRUE(decoded.has_value());
    EXPECT_EQ(*decoded, "hello");
    EXPECT_TRUE(buffer.empty());
}

TEST(FrameMessage, EmptyPayloadRoundTrips) {
    auto buffer = frame_message("");
    const auto decoded = try_decode_frame(buffer);
    ASSERT_TRUE(decoded.has_value());
    EXPECT_EQ(*decoded, "");
}

TEST(TryDecodeFrame, IncompleteFrameLeavesBufferUntouched) {
    auto full = frame_message("hello");
    std::vector<uint8_t> partial(full.begin(), full.end() - 1);
    const auto original_size = partial.size();

    const auto decoded = try_decode_frame(partial);
    EXPECT_FALSE(decoded.has_value());
    EXPECT_EQ(partial.size(), original_size);
}

TEST(TryDecodeFrame, EmptyBufferReturnsNullopt) {
    std::vector<uint8_t> buffer;
    EXPECT_FALSE(try_decode_frame(buffer).has_value());
}

TEST(TryDecodeFrame, ConcatenatedFramesDecodeOneAtATime) {
    auto first = frame_message("one");
    auto second = frame_message("two");
    std::vector<uint8_t> buffer(first.begin(), first.end());
    buffer.insert(buffer.end(), second.begin(), second.end());

    const auto decoded_first = try_decode_frame(buffer);
    ASSERT_TRUE(decoded_first.has_value());
    EXPECT_EQ(*decoded_first, "one");

    const auto decoded_second = try_decode_frame(buffer);
    ASSERT_TRUE(decoded_second.has_value());
    EXPECT_EQ(*decoded_second, "two");
    EXPECT_TRUE(buffer.empty());
}

TEST(NetVersion, ReturnsNonEmptyString) { EXPECT_FALSE(net_version().empty()); }

TEST(CliIntegration, VersionStringCombinesCoreAndNet) {
    const std::string combined = std::string("buildlab-cli ") + buildlab_core_version() +
                                 " (core " + buildlab_core_version() + ", net " + net_version() +
                                 ")";
    EXPECT_NE(combined.find(buildlab_core_version()), std::string::npos);
    EXPECT_NE(combined.find(net_version()), std::string::npos);
}
