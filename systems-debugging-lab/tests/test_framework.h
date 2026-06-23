#pragma once

#include <iostream>

namespace logforge::test {

inline int& failure_count() {
    static int count = 0;
    return count;
}

}  // namespace logforge::test

#define LF_CHECK(cond)                                                                      \
    do {                                                                                     \
        if (!(cond)) {                                                                       \
            std::cerr << "CHECK failed at " << __FILE__ << ":" << __LINE__ << ": " << #cond  \
                       << "\n";                                                              \
            ++::logforge::test::failure_count();                                             \
        }                                                                                     \
    } while (0)

#define LF_TEST_MAIN_BEGIN() int main() {
#define LF_TEST_MAIN_END()                                                       \
    if (::logforge::test::failure_count() > 0) {                                 \
        std::cerr << ::logforge::test::failure_count() << " check(s) failed\n";  \
        return 1;                                                                \
    }                                                                            \
    std::cout << "All checks passed\n";                                          \
    return 0;                                                                    \
    }
