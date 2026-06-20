#include "Aggregator.h"

#include <algorithm>

namespace logforge {

void Aggregator::add(const LogRecord& record) {
    ++status_counts_[record.status];
    ++ip_counts_[record.ip];
    ++path_counts_[record.path];
    latencies_.push_back(record.latency_ms);
    ++total_records_;
    if (record.status >= 400) {
        ++error_count_;
    }
}

void Aggregator::merge(const Aggregator& other) {
    for (const auto& [status, count] : other.status_counts_) {
        status_counts_[status] += count;
    }
    for (const auto& [ip, count] : other.ip_counts_) {
        ip_counts_[ip] += count;
    }
    for (const auto& [path, count] : other.path_counts_) {
        path_counts_[path] += count;
    }
    latencies_.insert(latencies_.end(), other.latencies_.begin(), other.latencies_.end());
    error_count_ += other.error_count_;
    total_records_ += other.total_records_;
}

std::vector<std::pair<std::string, std::uint64_t>> top_k(
    const std::unordered_map<std::string, std::uint64_t>& counts, std::size_t k) {
    std::vector<std::pair<std::string, std::uint64_t>> entries(counts.begin(), counts.end());
    std::sort(entries.begin(), entries.end(), [](const auto& a, const auto& b) {
        if (a.second != b.second) {
            return a.second > b.second;
        }
        return a.first < b.first;
    });
    if (entries.size() > k) {
        entries.resize(k);
    }
    return entries;
}

LatencyStats compute_latency_stats(std::vector<int> latencies) {
    LatencyStats stats;
    if (latencies.empty()) {
        return stats;
    }
    std::sort(latencies.begin(), latencies.end());

    auto percentile = [&latencies](double p) {
        std::size_t index = static_cast<std::size_t>(p * static_cast<double>(latencies.size() - 1));
        return latencies[index];
    };

    stats.p50 = percentile(0.50);
    stats.p95 = percentile(0.95);
    stats.p99 = percentile(0.99);
    stats.max = latencies.back();
    return stats;
}

}  // namespace logforge
