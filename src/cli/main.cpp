#include "buildlab/core.h"
#include "buildlab/net.hpp"

#include <cstring>
#include <iostream>
#include <string>
#include <vector>

namespace {

void print_help() {
    std::cout << "buildlab-cli -- demo CLI exercising buildlab_core and buildlab_net\n\n"
              << "Usage:\n"
              << "  buildlab-cli --help\n"
              << "  buildlab-cli --version\n"
              << "  buildlab-cli trim <text>\n"
              << "  buildlab-cli count <haystack> <needle>\n"
              << "  buildlab-cli addr <host:port>\n"
              << "  buildlab-cli frame <text>\n";
}

void print_version() {
    std::cout << "buildlab-cli " << buildlab_core_version() << " (core " << buildlab_core_version()
              << ", net " << buildlab::net::net_version() << ")\n";
}

int cmd_trim(const std::string &text) {
    std::vector<char> buffer(text.begin(), text.end());
    buffer.push_back('\0');
    std::cout << "'" << buildlab_trim(buffer.data()) << "'\n";
    return 0;
}

int cmd_count(const std::string &haystack, const std::string &needle) {
    std::cout << buildlab_count_occurrences(haystack.c_str(), needle.c_str()) << "\n";
    return 0;
}

int cmd_addr(const std::string &text) {
    const auto address = buildlab::net::parse_address(text);
    if (!address) {
        std::cerr << "error: could not parse address '" << text << "'\n";
        return 1;
    }
    std::cout << "host=" << address->host << " port=" << address->port << " ("
              << buildlab::net::format_address(*address) << ")\n";
    return 0;
}

int cmd_frame(const std::string &text) {
    const auto encoded = buildlab::net::frame_message(text);
    std::vector<uint8_t> buffer(encoded.begin(), encoded.end());
    const auto decoded = buildlab::net::try_decode_frame(buffer);
    if (!decoded) {
        std::cerr << "error: failed to decode the frame we just encoded\n";
        return 1;
    }
    std::cout << "encoded " << encoded.size() << " bytes, decoded payload: '" << *decoded << "'\n";
    return 0;
}

} // namespace

int main(int argc, char **argv) {
    if (argc < 2) {
        print_help();
        return 1;
    }

    const std::string command = argv[1];

    if (command == "--help" || command == "-h") {
        print_help();
        return 0;
    }
    if (command == "--version" || command == "-v") {
        print_version();
        return 0;
    }
    if (command == "trim" && argc >= 3) {
        return cmd_trim(argv[2]);
    }
    if (command == "count" && argc >= 4) {
        return cmd_count(argv[2], argv[3]);
    }
    if (command == "addr" && argc >= 3) {
        return cmd_addr(argv[2]);
    }
    if (command == "frame" && argc >= 3) {
        return cmd_frame(argv[2]);
    }

    std::cerr << "error: unrecognized or incomplete command '" << command << "'\n\n";
    print_help();
    return 1;
}
