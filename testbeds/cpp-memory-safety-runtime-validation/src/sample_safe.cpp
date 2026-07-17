// sample_safe.cpp — MOCK C++ file demonstrating SAFE PATTERNS
// This file shows how the same functionality should be written safely.
// FOR VALIDATION TESTING ONLY. Not intended for production compilation.

#include <iostream>
#include <string>
#include <memory>
#include <vector>
#include <array>
#include <limits>
#include <mutex>
#include <optional>

// SAFE-001: Use std::string instead of char arrays
void safe_string_example(const std::string& input) {
    std::string buffer = input;  // Automatically bounds-safe
    std::cout << buffer << std::endl;
}

// SAFE-002: Use smart pointers (unique_ptr) instead of raw malloc/free
class SafeBuffer {
    std::unique_ptr<char[]> data_;
    size_t size_;
public:
    explicit SafeBuffer(size_t size) : data_(std::make_unique<char[]>(size)), size_(size) {}
    char& operator[](size_t i) {
        if (i >= size_) throw std::out_of_range("buffer index out of bounds");
        return data_[i];
    }
};

// SAFE-003: Checked arithmetic for allocation
std::optional<size_t> safe_allocation_size(size_t count, size_t elem_size) {
    if (count > std::numeric_limits<size_t>::max() / elem_size) {
        return std::nullopt;  // Would overflow
    }
    return count * elem_size;
}

// SAFE-004: Format string literal
void safe_printf_example(const std::string& user_input) {
    printf("%s", user_input.c_str());  // Format string is literal
}

// SAFE-005: Thread-safe counter
class ThreadSafeCounter {
    int value_ = 0;
    mutable std::mutex mtx_;
public:
    void increment() {
        std::lock_guard<std::mutex> lock(mtx_);
        ++value_;
    }
    int get() const {
        std::lock_guard<std::mutex> lock(mtx_);
        return value_;
    }
};

// SAFE-006: Bounded file parser
class SafeFileParser {
    static constexpr size_t MAX_SIZE = 1024 * 1024;  // 1MB
    std::vector<char> buffer_;

public:
    bool parse(const std::string& path) {
        // size check, bounded read, validation...
        buffer_.reserve(MAX_SIZE);
        return true;
    }
};
