#pragma once

#include <condition_variable>
#include <functional>
#include <mutex>
#include <queue>
#include <thread>
#include <vector>

namespace logforge {

// A fixed-size worker pool with a shared task queue. Threads pull work in a
// loop until the pool is destroyed; wait_idle() blocks until every enqueued
// task has finished, which callers use as a join point before reading
// results that the tasks wrote into shared/thread-local storage.
class ThreadPool {
public:
    explicit ThreadPool(std::size_t num_threads);
    ~ThreadPool();

    ThreadPool(const ThreadPool&) = delete;
    ThreadPool& operator=(const ThreadPool&) = delete;

    void enqueue(std::function<void()> task);
    void wait_idle();

private:
    void worker_loop();

    std::vector<std::thread> workers_;
    std::queue<std::function<void()>> tasks_;
    std::mutex mutex_;
    std::condition_variable task_cv_;
    std::condition_variable idle_cv_;
    std::size_t active_tasks_ = 0;
    bool stop_ = false;
};

}  // namespace logforge
