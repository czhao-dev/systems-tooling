#pragma once

#include <cstddef>
#include <string>
#include <unordered_map>
#include <vector>

#include "LogRecord.h"

namespace logforge {

// Maps field values to the indices (into the records vector used to build
// the index) of all records with that value, so repeated queries can avoid a
// linear scan.
class LogIndex {
public:
    void build(const std::vector<LogRecord>& records);

    const std::vector<std::size_t>* lookup_status(int status) const;
    const std::vector<std::size_t>* lookup_ip(const std::string& ip) const;
    const std::vector<std::size_t>* lookup_path(const std::string& path) const;

private:
    std::unordered_map<int, std::vector<std::size_t>> status_index_;
    std::unordered_map<std::string, std::vector<std::size_t>> ip_index_;
    std::unordered_map<std::string, std::vector<std::size_t>> path_index_;
};

}  // namespace logforge
