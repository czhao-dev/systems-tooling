#include "QueryEngine.h"

#include <charconv>
#include <system_error>

namespace logforge {

std::optional<Query> parse_query(const std::string& query_str) {
    auto eq = query_str.find('=');
    if (eq == std::string::npos) {
        return std::nullopt;
    }
    Query query;
    query.field = query_str.substr(0, eq);
    query.value = query_str.substr(eq + 1);
    if (query.field != "status" && query.field != "ip" && query.field != "path") {
        return std::nullopt;
    }
    return query;
}

std::vector<std::size_t> execute_query(const Query& query, const std::vector<LogRecord>& records,
                                        const LogIndex* index) {
    if (query.field == "status") {
        int status = 0;
        auto result = std::from_chars(query.value.data(), query.value.data() + query.value.size(), status);
        if (result.ec != std::errc{}) {
            return {};
        }
        if (index != nullptr) {
            const auto* ids = index->lookup_status(status);
            return ids != nullptr ? *ids : std::vector<std::size_t>{};
        }
        std::vector<std::size_t> matches;
        for (std::size_t i = 0; i < records.size(); ++i) {
            if (records[i].status == status) {
                matches.push_back(i);
            }
        }
        return matches;
    }

    if (query.field == "ip" || query.field == "path") {
        if (index != nullptr) {
            const auto* ids =
                query.field == "ip" ? index->lookup_ip(query.value) : index->lookup_path(query.value);
            return ids != nullptr ? *ids : std::vector<std::size_t>{};
        }
        std::vector<std::size_t> matches;
        for (std::size_t i = 0; i < records.size(); ++i) {
            const std::string& field_value = query.field == "ip" ? records[i].ip : records[i].path;
            if (field_value == query.value) {
                matches.push_back(i);
            }
        }
        return matches;
    }

    return {};
}

}  // namespace logforge
