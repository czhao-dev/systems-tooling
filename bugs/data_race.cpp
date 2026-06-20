// Intentional data race on a shared map: demonstrates ThreadSanitizer.
#include <iostream>
#include <thread>
#include <unordered_map>
#include <vector>

int main() {
    std::unordered_map<int, int> status_counts;

    auto worker = [&status_counts]() {
        for (int i = 0; i < 100000; ++i) {
            status_counts[200]++;  // Unsynchronized concurrent writes.
        }
    };

    std::vector<std::thread> threads;
    for (int i = 0; i < 4; ++i) {
        threads.emplace_back(worker);
    }
    for (auto& t : threads) {
        t.join();
    }

    std::cout << "status 200 count: " << status_counts[200] << "\n";
    return 0;
}
