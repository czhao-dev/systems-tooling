#include <algorithm>
#include <fstream>
#include <iostream>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include "Aggregator.h"
#include "LogIndex.h"
#include "LogParser.h"
#include "QueryEngine.h"
#include "ReportWriter.h"
#include "ThreadPool.h"

namespace {

struct Options {
    std::string input;
    bool status_counts = false;
    bool latency_stats = false;
    bool errors_only = false;
    bool build_index = false;
    std::optional<std::size_t> top_ips;
    std::optional<std::size_t> top_paths;
    std::size_t threads = 1;
    std::optional<std::string> query;
};

void print_usage(const char* program_name) {
    std::cerr << "Usage: " << program_name << " --input <file> [options]\n"
              << "Options:\n"
              << "  --status-counts        Print status-code counts\n"
              << "  --top-ips <n>          Print the top n client IPs\n"
              << "  --top-paths <n>        Print the top n request paths\n"
              << "  --latency-stats        Print latency percentiles\n"
              << "  --errors-only          Print records with status >= 400\n"
              << "  --threads <n>          Number of worker threads (default 1)\n"
              << "  --build-index          Build an in-memory query index\n"
              << "  --query <expr>         Query records, e.g. status=500\n";
}

std::optional<Options> parse_args(int argc, char** argv) {
    Options options;
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        auto next_value = [&](const char* flag_name) -> std::optional<std::string> {
            if (i + 1 >= argc) {
                std::cerr << flag_name << " requires a value\n";
                return std::nullopt;
            }
            return std::string(argv[++i]);
        };

        if (arg == "--input") {
            auto value = next_value("--input");
            if (!value) return std::nullopt;
            options.input = *value;
        } else if (arg == "--status-counts") {
            options.status_counts = true;
        } else if (arg == "--top-ips") {
            auto value = next_value("--top-ips");
            if (!value) return std::nullopt;
            options.top_ips = std::stoul(*value);
        } else if (arg == "--top-paths") {
            auto value = next_value("--top-paths");
            if (!value) return std::nullopt;
            options.top_paths = std::stoul(*value);
        } else if (arg == "--latency-stats") {
            options.latency_stats = true;
        } else if (arg == "--errors-only") {
            options.errors_only = true;
        } else if (arg == "--threads") {
            auto value = next_value("--threads");
            if (!value) return std::nullopt;
            options.threads = std::stoul(*value);
        } else if (arg == "--build-index") {
            options.build_index = true;
        } else if (arg == "--query") {
            auto value = next_value("--query");
            if (!value) return std::nullopt;
            options.query = *value;
        } else {
            std::cerr << "Unknown argument: " << arg << "\n";
            return std::nullopt;
        }
    }

    if (options.input.empty()) {
        std::cerr << "--input is required\n";
        return std::nullopt;
    }
    if (options.threads == 0) {
        options.threads = 1;
    }
    return options;
}

std::vector<std::string> read_lines(const std::string& path) {
    std::ifstream file(path);
    if (!file) {
        throw std::runtime_error("failed to open input file: " + path);
    }
    std::vector<std::string> lines;
    std::string line;
    while (std::getline(file, line)) {
        lines.push_back(std::move(line));
    }
    return lines;
}

struct ParseResult {
    logforge::Aggregator aggregator;
    std::vector<logforge::LogRecord> records;
    std::size_t malformed_count = 0;
};

// Splits lines into num_threads contiguous chunks. Each worker parses its
// chunk into a thread-local Aggregator (avoiding any shared mutable state
// during the parallel phase), and the chunks are merged into one Aggregator
// afterward. Per-line parse results are written into a pre-sized vector at
// each line's own index, so no merge step is needed to reconstruct order.
ParseResult parse_lines(const std::vector<std::string>& lines, std::size_t num_threads, bool keep_records) {
    std::vector<std::optional<logforge::LogRecord>> parsed(lines.size());
    std::vector<logforge::Aggregator> local_aggregators(num_threads);
    std::vector<std::size_t> local_malformed(num_threads, 0);

    {
        logforge::ThreadPool pool(num_threads);
        std::size_t chunk_size = (lines.size() + num_threads - 1) / num_threads;
        for (std::size_t t = 0; t < num_threads; ++t) {
            std::size_t start = t * chunk_size;
            std::size_t end = std::min(start + chunk_size, lines.size());
            if (start >= end) {
                continue;
            }
            pool.enqueue([&, t, start, end] {
                for (std::size_t i = start; i < end; ++i) {
                    auto record = logforge::parse_line(lines[i]);
                    if (record) {
                        local_aggregators[t].add(*record);
                        parsed[i] = std::move(record);
                    } else {
                        ++local_malformed[t];
                    }
                }
            });
        }
        pool.wait_idle();
    }

    ParseResult result;
    for (std::size_t t = 0; t < num_threads; ++t) {
        result.aggregator.merge(local_aggregators[t]);
        result.malformed_count += local_malformed[t];
    }

    if (keep_records) {
        result.records.reserve(result.aggregator.total_records());
        for (auto& record : parsed) {
            if (record) {
                result.records.push_back(std::move(*record));
            }
        }
    }

    return result;
}

}  // namespace

int main(int argc, char** argv) {
    auto options = parse_args(argc, argv);
    if (!options) {
        print_usage(argv[0]);
        return 1;
    }

    std::vector<std::string> lines;
    try {
        lines = read_lines(options->input);
    } catch (const std::exception& e) {
        std::cerr << e.what() << "\n";
        return 1;
    }

    bool keep_records = options->errors_only || options->build_index || options->query.has_value();
    ParseResult result = parse_lines(lines, options->threads, keep_records);

    if (result.malformed_count > 0) {
        std::cerr << "Skipped " << result.malformed_count << " malformed line(s)\n";
    }

    logforge::LogIndex index;
    bool have_index = false;
    if (options->build_index) {
        index.build(result.records);
        have_index = true;
        std::cout << "Index built (" << result.records.size() << " records indexed)\n";
    }

    bool printed_section = false;
    auto separate = [&] {
        if (printed_section) {
            std::cout << "\n";
        }
        printed_section = true;
    };

    if (options->status_counts) {
        separate();
        logforge::write_status_counts(std::cout, result.aggregator);
    }
    if (options->top_ips) {
        separate();
        logforge::write_top_ips(std::cout, result.aggregator, *options->top_ips);
    }
    if (options->top_paths) {
        separate();
        logforge::write_top_paths(std::cout, result.aggregator, *options->top_paths);
    }
    if (options->latency_stats) {
        separate();
        logforge::write_latency_stats(std::cout, result.aggregator);
    }
    if (options->errors_only) {
        separate();
        logforge::write_errors_only(std::cout, result.records);
    }
    if (options->query) {
        auto query = logforge::parse_query(*options->query);
        if (!query) {
            std::cerr << "Invalid query: " << *options->query << "\n";
            return 1;
        }
        auto matches = logforge::execute_query(*query, result.records, have_index ? &index : nullptr);
        separate();
        logforge::write_query_results(std::cout, result.records, matches);
    }

    return 0;
}
