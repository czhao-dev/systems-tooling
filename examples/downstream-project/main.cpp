#include "buildlab/core.h"
#include "buildlab/net.hpp"

#include <iostream>

// Smoke test for downstream consumption: confirms find_package(buildlab)
// and the exported buildlab::core / buildlab::net targets work end-to-end
// from outside this repository's own build tree.
int main() {
    std::cout << "buildlab_core version: " << buildlab_core_version() << "\n";

    const auto address = buildlab::net::parse_address("downstream.example:9000");
    if (!address) {
        std::cerr << "failed to parse address\n";
        return 1;
    }
    std::cout << "buildlab_net parsed address: " << buildlab::net::format_address(*address) << "\n";

    return 0;
}
