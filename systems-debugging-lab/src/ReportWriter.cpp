#include "ReportWriter.h"

namespace logforge {

void write_status_counts(std::ostream& os, const Aggregator& agg) {
    os << "Status Counts\n";
    os << "-------------\n";
    for (const auto& [status, count] : agg.status_counts()) {
        os << status << ": " << count << "\n";
    }
}

void write_top_ips(std::ostream& os, const Aggregator& agg, std::size_t k) {
    os << "Top IPs\n";
    os << "-------\n";
    for (const auto& [ip, count] : top_k(agg.ip_counts(), k)) {
        os << ip << ": " << count << "\n";
    }
}

void write_top_paths(std::ostream& os, const Aggregator& agg, std::size_t k) {
    os << "Top Paths\n";
    os << "---------\n";
    for (const auto& [path, count] : top_k(agg.path_counts(), k)) {
        os << path << ": " << count << "\n";
    }
}

void write_latency_stats(std::ostream& os, const Aggregator& agg) {
    LatencyStats stats = compute_latency_stats(agg.latencies());
    os << "Latency Statistics\n";
    os << "------------------\n";
    os << "p50: " << stats.p50 << " ms\n";
    os << "p95: " << stats.p95 << " ms\n";
    os << "p99: " << stats.p99 << " ms\n";
    os << "max: " << stats.max << " ms\n";
}

void write_errors_only(std::ostream& os, const std::vector<LogRecord>& records) {
    os << "Errors\n";
    os << "------\n";
    for (const auto& record : records) {
        if (record.status >= 400) {
            os << record.timestamp << " " << record.ip << " " << record.method << " " << record.path
               << " " << record.status << " " << record.latency_ms << "ms\n";
        }
    }
}

void write_query_results(std::ostream& os, const std::vector<LogRecord>& records,
                          const std::vector<std::size_t>& matching_ids) {
    os << "Query Results (" << matching_ids.size() << " match(es))\n";
    os << "-----------------------------\n";
    for (std::size_t id : matching_ids) {
        const LogRecord& record = records[id];
        os << record.timestamp << " " << record.ip << " " << record.method << " " << record.path << " "
           << record.status << " " << record.latency_ms << "ms\n";
    }
}

}  // namespace logforge
