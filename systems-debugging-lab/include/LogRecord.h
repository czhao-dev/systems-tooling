#pragma once

#include <string>

namespace logforge {

struct LogRecord {
    std::string timestamp;
    std::string ip;
    std::string method;
    std::string path;
    int status = 0;
    int latency_ms = 0;
};

}  // namespace logforge
