// Intentional stack buffer overflow: demonstrates AddressSanitizer.
#include <cstring>
#include <iostream>

void copy_method(const char* token) {
    char method[4];  // Too small for "POST" plus its null terminator.
    std::strcpy(method, token);
    std::cout << "method: " << method << "\n";
}

int main() {
    copy_method("POST");
    return 0;
}
