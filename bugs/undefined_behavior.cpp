// Intentional signed integer overflow: demonstrates UndefinedBehaviorSanitizer.
#include <iostream>
#include <limits>

int sum_latencies(int count) {
    int total = 0;  // Should be int64_t to hold sums over large inputs.
    for (int i = 0; i < count; ++i) {
        total += std::numeric_limits<int>::max() / 2;
    }
    return total;
}

int main() {
    std::cout << "total: " << sum_latencies(10) << "\n";
    return 0;
}
