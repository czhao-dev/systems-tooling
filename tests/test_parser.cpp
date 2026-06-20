#include "LogParser.h"
#include "test_framework.h"

using logforge::parse_line;

LF_TEST_MAIN_BEGIN()
    {
        auto record = parse_line("2026-06-19T10:15:21Z 192.168.1.10 GET /api/users 200 34ms");
        LF_CHECK(record.has_value());
        LF_CHECK(record->timestamp == "2026-06-19T10:15:21Z");
        LF_CHECK(record->ip == "192.168.1.10");
        LF_CHECK(record->method == "GET");
        LF_CHECK(record->path == "/api/users");
        LF_CHECK(record->status == 200);
        LF_CHECK(record->latency_ms == 34);
    }
    {
        // Missing fields.
        auto record = parse_line("2026-06-19T10:15:21Z 192.168.1.10 GET /api/users");
        LF_CHECK(!record.has_value());
    }
    {
        // Non-numeric status.
        auto record = parse_line("2026-06-19T10:15:21Z 192.168.1.10 GET /api/users abc 34ms");
        LF_CHECK(!record.has_value());
    }
    {
        // Latency missing the "ms" suffix.
        auto record = parse_line("2026-06-19T10:15:21Z 192.168.1.10 GET /api/users 200 34");
        LF_CHECK(!record.has_value());
    }
    {
        auto record = parse_line("");
        LF_CHECK(!record.has_value());
    }
    {
        // Trailing carriage return (e.g. CRLF-terminated log files) is tolerated.
        auto record = parse_line("2026-06-19T10:15:21Z 192.168.1.10 GET /api/users 200 34ms\r");
        LF_CHECK(record.has_value());
        LF_CHECK(record->latency_ms == 34);
    }
LF_TEST_MAIN_END()
