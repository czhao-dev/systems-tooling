#pragma once

#include <optional>
#include <string>
#include <vector>

#include "LogIndex.h"
#include "LogRecord.h"

namespace logforge {

struct Query {
    std::string field;  // "status", "ip", or "path"
    std::string value;
};

// Parses queries of the form "field=value", e.g. "status=500".
std::optional<Query> parse_query(const std::string& query_str);

// Executes the query against records. Uses the index when one is provided
// (non-null); otherwise falls back to a linear scan over records.
std::vector<std::size_t> execute_query(const Query& query,
                                        const std::vector<LogRecord>& records,
                                        const LogIndex* index);

}  // namespace logforge
