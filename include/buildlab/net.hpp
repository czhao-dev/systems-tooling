#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace buildlab::net {

struct Address {
    std::string host;
    uint16_t port = 0;
};

/* Parses "host:port" into an Address. Returns std::nullopt on malformed
 * input: missing colon, empty host, non-numeric port, or a port outside
 * [0, 65535]. As a deliberate simplification this splits on the last ':',
 * so bare IPv6 literals (which contain multiple colons) are out of scope. */
std::optional<Address> parse_address(std::string_view text);

/* Renders an Address back to "host:port" form. */
std::string format_address(const Address &address);

/* Encodes payload as a 4-byte big-endian length prefix followed by the
 * payload bytes -- a minimal length-prefixed framing scheme, the same
 * technique used by many real wire protocols to delimit messages on a
 * byte stream. */
std::vector<uint8_t> frame_message(std::string_view payload);

/* Attempts to decode one length-prefixed frame from the front of buffer.
 * On success, returns the decoded payload and erases the consumed bytes
 * from buffer. Returns std::nullopt (leaving buffer untouched) if buffer
 * does not yet contain a complete frame. */
std::optional<std::string> try_decode_frame(std::vector<uint8_t> &buffer);

/* Returns the buildlab_net semantic version string, e.g. "0.1.0". */
std::string net_version();

} // namespace buildlab::net
