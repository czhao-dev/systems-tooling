// Intentionally leaks memory on every call: demonstrates Valgrind Memcheck
// and LeakSanitizer.
#include <cstdio>
#include <string>

struct Node {
    std::string value;
    Node* next;
};

Node* build_chain(int length) {
    Node* head = nullptr;
    for (int i = 0; i < length; ++i) {
        head = new Node{"item-" + std::to_string(i), head};  // Never freed.
    }
    return head;
}

int main() {
    for (int i = 0; i < 1000; ++i) {
        Node* chain = build_chain(10);
        std::printf("built chain starting at %p\n", static_cast<void*>(chain));
    }
    return 0;
}
