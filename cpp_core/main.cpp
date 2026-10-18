#include <windows.h>
#include <iostream>
#include <thread>
#include <chrono>

int main() {
    std::cout << "[VESTA C++] External Core Initialized." << std::endl;
    while (true) {
        // Логика чтения памяти (на ПК)
        std::this_thread::sleep_for(std::chrono::milliseconds(16));
    }
    return 0;
}
