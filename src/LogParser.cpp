#include "LogParser.h"

#include <array>
#include <charconv>
#include <string>
#include <system_error>

namespace logforge {

namespace {

// Splits line on single spaces into exactly Count tokens. Returns false if
// the line has a different number of tokens.
template <std::size_t Count>
bool split_tokens(std::string_view line, std::array<std::string_view, Count>& tokens) {
    std::size_t token_index = 0;
    std::size_t pos = 0;
    while (pos <= line.size()) {
        std::size_t next = line.find(' ', pos);
        std::string_view token =
            (next == std::string_view::npos) ? line.substr(pos) : line.substr(pos, next - pos);
        if (token_index >= Count) {
            return false;  // Too many tokens.
        }
        tokens[token_index++] = token;
        if (next == std::string_view::npos) {
            break;
        }
        pos = next + 1;
    }
    return token_index == Count;
}

bool parse_int(std::string_view text, int& out) {
    if (text.empty()) {
        return false;
    }
    auto result = std::from_chars(text.data(), text.data() + text.size(), out);
    return result.ec == std::errc{} && result.ptr == text.data() + text.size();
}

}  // namespace

std::optional<LogRecord> parse_line(std::string_view line) {
    if (!line.empty() && line.back() == '\r') {
        line.remove_suffix(1);
    }
    if (line.empty()) {
        return std::nullopt;
    }

    std::array<std::string_view, 6> tokens;
    if (!split_tokens(line, tokens)) {
        return std::nullopt;
    }

    int status = 0;
    if (!parse_int(tokens[4], status)) {
        return std::nullopt;
    }

    std::string_view latency_token = tokens[5];
    if (latency_token.size() < 3 || latency_token.substr(latency_token.size() - 2) != "ms") {
        return std::nullopt;
    }
    int latency_ms = 0;
    if (!parse_int(latency_token.substr(0, latency_token.size() - 2), latency_ms)) {
        return std::nullopt;
    }

    LogRecord record;
    record.timestamp = std::string(tokens[0]);
    record.ip = std::string(tokens[1]);
    record.method = std::string(tokens[2]);
    record.path = std::string(tokens[3]);
    record.status = status;
    record.latency_ms = latency_ms;
    return record;
}

}  // namespace logforge
