// Intentionally crashes on a malformed log line: demonstrates GDB and LLDB.
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

struct LogRecord {
    std::string timestamp;
    std::string ip;
    std::string method;
    std::string path;
    std::string status;
    std::string latency;
};

LogRecord parse_unsafe(const std::string& line) {
    std::istringstream iss(line);
    std::vector<std::string> tokens;
    std::string token;
    while (iss >> token) {
        tokens.push_back(token);
    }
    // Assumes six tokens are always present; out-of-range access on bad input.
    return LogRecord{tokens.at(0), tokens.at(1), tokens.at(2), tokens.at(3), tokens.at(4), tokens.at(5)};
}

int main() {
    std::string malformed_line = "2026-06-19T10:15:21Z 192.168.1.10 GET";
    LogRecord record = parse_unsafe(malformed_line);
    std::cout << "parsed status: " << record.status << "\n";
    return 0;
}
