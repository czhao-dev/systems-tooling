#include <atomic>

#include "ThreadPool.h"
#include "test_framework.h"

using logforge::ThreadPool;

LF_TEST_MAIN_BEGIN()
    {
        ThreadPool pool(4);
        std::atomic<int> counter{0};
        constexpr int kTasks = 1000;
        for (int i = 0; i < kTasks; ++i) {
            pool.enqueue([&counter] { ++counter; });
        }
        pool.wait_idle();
        LF_CHECK(counter.load() == kTasks);
    }
    {
        // wait_idle() can be called more than once and still report idle.
        ThreadPool pool(2);
        pool.wait_idle();
        LF_CHECK(true);
    }
LF_TEST_MAIN_END()
