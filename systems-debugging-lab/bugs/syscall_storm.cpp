// Intentionally performs one read() syscall per byte: demonstrates
// strace/dtruss syscall tracing.
#include <cstdio>
#include <iostream>

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "usage: " << argv[0] << " <file>\n";
        return 1;
    }
    FILE* file = std::fopen(argv[1], "rb");
    if (!file) {
        std::cerr << "failed to open " << argv[1] << "\n";
        return 1;
    }
    std::setvbuf(file, nullptr, _IONBF, 0);  // Disable buffering.

    std::size_t byte_count = 0;
    int ch;
    while ((ch = std::fgetc(file)) != EOF) {  // One read() syscall per byte.
        ++byte_count;
        (void)ch;
    }
    std::fclose(file);

    std::cout << "read " << byte_count << " bytes, one syscall at a time\n";
    return 0;
}
