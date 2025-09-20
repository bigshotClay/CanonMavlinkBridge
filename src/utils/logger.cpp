/**
 * @file logger.cpp
 * @brief Logger implementation (stub)
 */

// Placeholder implementation for testing MAVSDK compilation

#include <iostream>
#include <string>

void log_info(const std::string& message) {
    std::cout << "INFO: " << message << std::endl;
}

void log_error(const std::string& message) {
    std::cerr << "ERROR: " << message << std::endl;
}