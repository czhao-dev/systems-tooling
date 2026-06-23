// Intentional use-after-free: demonstrates AddressSanitizer and Valgrind.
#include <iostream>

struct Record {
    int status;
};

int main() {
    Record* record = new Record{200};
    delete record;
    std::cout << "status after free: " << record->status << "\n";
    return 0;
}
