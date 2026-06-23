#include "Aggregator.h"
#include "test_framework.h"

using logforge::Aggregator;
using logforge::compute_latency_stats;
using logforge::LogRecord;
using logforge::top_k;

LF_TEST_MAIN_BEGIN()
    {
        Aggregator agg;
        agg.add(LogRecord{"t1", "1.1.1.1", "GET", "/a", 200, 10});
        agg.add(LogRecord{"t2", "1.1.1.1", "GET", "/a", 404, 20});
        agg.add(LogRecord{"t3", "1.1.1.2", "POST", "/b", 200, 30});

        LF_CHECK(agg.total_records() == 3);
        LF_CHECK(agg.error_count() == 1);
        LF_CHECK(agg.status_counts().at(200) == 2);
        LF_CHECK(agg.status_counts().at(404) == 1);
        LF_CHECK(agg.ip_counts().at("1.1.1.1") == 2);
        LF_CHECK(agg.path_counts().at("/b") == 1);
    }
    {
        Aggregator a;
        a.add(LogRecord{"t1", "1.1.1.1", "GET", "/a", 200, 10});
        Aggregator b;
        b.add(LogRecord{"t2", "1.1.1.1", "GET", "/a", 200, 20});
        a.merge(b);
        LF_CHECK(a.total_records() == 2);
        LF_CHECK(a.status_counts().at(200) == 2);
    }
    {
        std::unordered_map<std::string, std::uint64_t> counts{{"a", 3}, {"b", 5}, {"c", 1}};
        auto top = top_k(counts, 2);
        LF_CHECK(top.size() == 2);
        LF_CHECK(top[0].first == "b");
        LF_CHECK(top[1].first == "a");
    }
    {
        std::vector<int> latencies{10, 20, 30, 40, 50, 60, 70, 80, 90, 100};
        auto stats = compute_latency_stats(latencies);
        LF_CHECK(stats.max == 100);
        LF_CHECK(stats.p50 == 50);
    }
LF_TEST_MAIN_END()
