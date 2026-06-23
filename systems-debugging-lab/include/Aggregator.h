#pragma once

#include <cstdint>
#include <map>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "LogRecord.h"

namespace logforge {

class Aggregator {
public:
    void add(const LogRecord& record);
    void merge(const Aggregator& other);

    const std::map<int, std::uint64_t>& status_counts() const { return status_counts_; }
    const std::unordered_map<std::string, std::uint64_t>& ip_counts() const { return ip_counts_; }
    const std::unordered_map<std::string, std::uint64_t>& path_counts() const { return path_counts_; }
    const std::vector<int>& latencies() const { return latencies_; }
    std::uint64_t error_count() const { return error_count_; }
    std::uint64_t total_records() const { return total_records_; }

private:
    std::map<int, std::uint64_t> status_counts_;
    std::unordered_map<std::string, std::uint64_t> ip_counts_;
    std::unordered_map<std::string, std::uint64_t> path_counts_;
    std::vector<int> latencies_;
    std::uint64_t error_count_ = 0;
    std::uint64_t total_records_ = 0;
};

// Returns the top-k (key, count) pairs sorted by count descending, then key
// ascending to break ties deterministically.
std::vector<std::pair<std::string, std::uint64_t>> top_k(
    const std::unordered_map<std::string, std::uint64_t>& counts, std::size_t k);

struct LatencyStats {
    int p50 = 0;
    int p95 = 0;
    int p99 = 0;
    int max = 0;
};

LatencyStats compute_latency_stats(std::vector<int> latencies);

}  // namespace logforge
