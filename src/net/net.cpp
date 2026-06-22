#include "buildlab/net.hpp"

#include <charconv>
#include <cstring>

namespace buildlab::net {

namespace {

constexpr size_t kFrameHeaderSize = 4;

void append_be32(std::vector<uint8_t> &out, uint32_t value) {
    out.push_back(static_cast<uint8_t>((value >> 24) & 0xFF));
    out.push_back(static_cast<uint8_t>((value >> 16) & 0xFF));
    out.push_back(static_cast<uint8_t>((value >> 8) & 0xFF));
    out.push_back(static_cast<uint8_t>(value & 0xFF));
}

uint32_t read_be32(const uint8_t *bytes) {
    return (static_cast<uint32_t>(bytes[0]) << 24) | (static_cast<uint32_t>(bytes[1]) << 16) |
           (static_cast<uint32_t>(bytes[2]) << 8) | static_cast<uint32_t>(bytes[3]);
}

} // namespace

std::optional<Address> parse_address(std::string_view text) {
    const size_t colon = text.rfind(':');
    if (colon == std::string_view::npos || colon == 0 || colon == text.size() - 1) {
        return std::nullopt;
    }

    const std::string_view host = text.substr(0, colon);
    const std::string_view port_text = text.substr(colon + 1);

    unsigned long port_value = 0;
    const auto *begin = port_text.data();
    const auto *end = port_text.data() + port_text.size();
    const auto result = std::from_chars(begin, end, port_value);
    if (result.ec != std::errc() || result.ptr != end || port_value > 65535) {
        return std::nullopt;
    }

    return Address{std::string(host), static_cast<uint16_t>(port_value)};
}

std::string format_address(const Address &address) {
    return address.host + ":" + std::to_string(address.port);
}

std::vector<uint8_t> frame_message(std::string_view payload) {
    std::vector<uint8_t> out;
    out.reserve(kFrameHeaderSize + payload.size());
    append_be32(out, static_cast<uint32_t>(payload.size()));
    out.insert(out.end(), payload.begin(), payload.end());
    return out;
}

std::optional<std::string> try_decode_frame(std::vector<uint8_t> &buffer) {
    if (buffer.size() < kFrameHeaderSize) {
        return std::nullopt;
    }

    const uint32_t payload_size = read_be32(buffer.data());
    const size_t frame_size = kFrameHeaderSize + payload_size;
    if (buffer.size() < frame_size) {
        return std::nullopt;
    }

    std::string payload(reinterpret_cast<const char *>(buffer.data() + kFrameHeaderSize),
                        payload_size);
    buffer.erase(buffer.begin(), buffer.begin() + static_cast<ptrdiff_t>(frame_size));
    return payload;
}

std::string net_version() { return "0.1.0"; }

} // namespace buildlab::net
