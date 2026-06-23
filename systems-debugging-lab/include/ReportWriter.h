#pragma once

#include <cstddef>
#include <ostream>
#include <vector>

#include "Aggregator.h"
#include "LogRecord.h"

namespace logforge {

void write_status_counts(std::ostream& os, const Aggregator& agg);
void write_top_ips(std::ostream& os, const Aggregator& agg, std::size_t k);
void write_top_paths(std::ostream& os, const Aggregator& agg, std::size_t k);
void write_latency_stats(std::ostream& os, const Aggregator& agg);
void write_errors_only(std::ostream& os, const std::vector<LogRecord>& records);
void write_query_results(std::ostream& os, const std::vector<LogRecord>& records,
                          const std::vector<std::size_t>& matching_ids);

}  // namespace logforge
