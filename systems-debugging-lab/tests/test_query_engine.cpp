#include "LogIndex.h"
#include "QueryEngine.h"
#include "test_framework.h"

using logforge::execute_query;
using logforge::LogIndex;
using logforge::LogRecord;
using logforge::parse_query;

LF_TEST_MAIN_BEGIN()
    std::vector<LogRecord> records{
        LogRecord{"t1", "1.1.1.1", "GET", "/a", 200, 10},
        LogRecord{"t2", "1.1.1.2", "GET", "/b", 500, 20},
        LogRecord{"t3", "1.1.1.1", "POST", "/a", 500, 30},
    };

    {
        auto query = parse_query("status=500");
        LF_CHECK(query.has_value());
        LF_CHECK(query->field == "status");
        LF_CHECK(query->value == "500");
    }
    {
        auto query = parse_query("invalid-query");
        LF_CHECK(!query.has_value());
    }
    {
        auto query = parse_query("unknownfield=1");
        LF_CHECK(!query.has_value());
    }
    {
        auto query = parse_query("status=500");
        LF_CHECK(query.has_value());
        auto matches = execute_query(*query, records, nullptr);
        LF_CHECK(matches.size() == 2);
    }
    {
        LogIndex index;
        index.build(records);

        auto ip_query = parse_query("ip=1.1.1.1");
        LF_CHECK(ip_query.has_value());
        auto ip_matches = execute_query(*ip_query, records, &index);
        LF_CHECK(ip_matches.size() == 2);

        auto path_query = parse_query("path=/b");
        LF_CHECK(path_query.has_value());
        auto path_matches = execute_query(*path_query, records, &index);
        LF_CHECK(path_matches.size() == 1);

        auto missing_query = parse_query("ip=9.9.9.9");
        LF_CHECK(missing_query.has_value());
        auto missing_matches = execute_query(*missing_query, records, &index);
        LF_CHECK(missing_matches.empty());
    }
LF_TEST_MAIN_END()
