#include "LogIndex.h"

namespace logforge {

void LogIndex::build(const std::vector<LogRecord>& records) {
    status_index_.clear();
    ip_index_.clear();
    path_index_.clear();
    for (std::size_t i = 0; i < records.size(); ++i) {
        const LogRecord& record = records[i];
        status_index_[record.status].push_back(i);
        ip_index_[record.ip].push_back(i);
        path_index_[record.path].push_back(i);
    }
}

const std::vector<std::size_t>* LogIndex::lookup_status(int status) const {
    auto it = status_index_.find(status);
    return it == status_index_.end() ? nullptr : &it->second;
}

const std::vector<std::size_t>* LogIndex::lookup_ip(const std::string& ip) const {
    auto it = ip_index_.find(ip);
    return it == ip_index_.end() ? nullptr : &it->second;
}

const std::vector<std::size_t>* LogIndex::lookup_path(const std::string& path) const {
    auto it = path_index_.find(path);
    return it == path_index_.end() ? nullptr : &it->second;
}

}  // namespace logforge
