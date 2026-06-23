#pragma once

#include <optional>
#include <string_view>

#include "LogRecord.h"

namespace logforge {

// Parses one line of the form:
//   2026-06-19T10:15:21Z 192.168.1.10 GET /api/users 200 34ms
// Returns std::nullopt if the line does not have exactly six whitespace-
// separated fields or if the status/latency fields are not well-formed.
std::optional<LogRecord> parse_line(std::string_view line);

}  // namespace logforge
