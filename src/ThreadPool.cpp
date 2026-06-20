#include "ThreadPool.h"

namespace logforge {

ThreadPool::ThreadPool(std::size_t num_threads) {
    for (std::size_t i = 0; i < num_threads; ++i) {
        workers_.emplace_back([this] { worker_loop(); });
    }
}

ThreadPool::~ThreadPool() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        stop_ = true;
    }
    task_cv_.notify_all();
    for (auto& worker : workers_) {
        worker.join();
    }
}

void ThreadPool::enqueue(std::function<void()> task) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        tasks_.push(std::move(task));
        ++active_tasks_;
    }
    task_cv_.notify_one();
}

void ThreadPool::wait_idle() {
    std::unique_lock<std::mutex> lock(mutex_);
    idle_cv_.wait(lock, [this] { return active_tasks_ == 0; });
}

void ThreadPool::worker_loop() {
    while (true) {
        std::function<void()> task;
        {
            std::unique_lock<std::mutex> lock(mutex_);
            task_cv_.wait(lock, [this] { return stop_ || !tasks_.empty(); });
            if (tasks_.empty()) {
                if (stop_) {
                    return;
                }
                continue;
            }
            task = std::move(tasks_.front());
            tasks_.pop();
        }

        task();

        {
            std::lock_guard<std::mutex> lock(mutex_);
            --active_tasks_;
            if (active_tasks_ == 0) {
                idle_cv_.notify_all();
            }
        }
    }
}

}  // namespace logforge
