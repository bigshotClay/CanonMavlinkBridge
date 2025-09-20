/**
 * @file main.cpp
 * @brief Main entry point for CanonMavlinkBridge
 *
 * Minimal implementation for testing MAVSDK compilation
 */

#include <iostream>
#include <memory>
#include <signal.h>
#include <chrono>
#include <thread>

// MAVSDK includes
#include <mavsdk/mavsdk.h>
#include <mavsdk/system.h>
#include <plugins/camera/camera.h>
#include <plugins/ftp/ftp.h>

using namespace mavsdk;

// Global flag for clean shutdown
volatile sig_atomic_t should_exit = 0;

void signal_handler(int signal) {
    should_exit = 1;
    std::cout << "Received signal " << signal << ", shutting down..." << std::endl;
}

int main(int argc, char* argv[]) {
    std::cout << "CanonMavlinkBridge starting..." << std::endl;

    // Set up signal handling
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // Create MAVSDK instance
    Mavsdk mavsdk;
    Mavsdk::Configuration config(Mavsdk::Configuration::UsageType::CompanionComputer);
    mavsdk.set_configuration(config);

    // Test connection string - default to UDP
    std::string connection_url = "udp://0.0.0.0:14540";
    if (argc > 1) {
        connection_url = argv[1];
    }

    std::cout << "Adding connection: " << connection_url << std::endl;

    // Add connection
    ConnectionResult connection_result = mavsdk.add_any_connection(connection_url);
    if (connection_result != ConnectionResult::Success) {
        std::cerr << "Connection failed: " << connection_result << std::endl;
        return -1;
    }

    std::cout << "Waiting for system to connect..." << std::endl;

    // Wait for system connection (with timeout)
    auto systems = mavsdk.systems();
    std::shared_ptr<System> system = nullptr;

    if (!systems.empty()) {
        system = systems[0];
        std::cout << "System connected!" << std::endl;
    } else {
        std::cout << "No systems found, continuing anyway for testing..." << std::endl;
        // Create a dummy system for testing plugin availability
        system = nullptr;
    }

    // Test camera plugin availability
    std::cout << "Testing camera plugin availability..." << std::endl;
    if (system) {
        try {
            auto camera = Camera{system};
            std::cout << "Camera plugin instantiated successfully" << std::endl;

            // Test basic camera functionality
            auto result = camera.set_mode(Camera::Mode::Photo);
            if (result != Camera::Result::Success) {
                std::cout << "Failed to set camera mode: " << result << std::endl;
            } else {
                std::cout << "Camera mode set successfully" << std::endl;
            }
        } catch (const std::exception& e) {
            std::cout << "Camera plugin error: " << e.what() << std::endl;
        }
    } else {
        std::cout << "Camera plugin available (no system to test with)" << std::endl;
    }

    // Test FTP plugin availability
    std::cout << "Testing FTP plugin availability..." << std::endl;
    if (system) {
        try {
            auto ftp = Ftp{system};
            std::cout << "FTP plugin instantiated successfully" << std::endl;

            // Test basic FTP functionality
            auto list_result = ftp.list_directory("/");
            if (list_result.first != Ftp::Result::Success) {
                std::cout << "Failed to list directory: " << list_result.first << std::endl;
            } else {
                std::cout << "FTP directory listing successful" << std::endl;
            }
        } catch (const std::exception& e) {
            std::cout << "FTP plugin error: " << e.what() << std::endl;
        }
    } else {
        std::cout << "FTP plugin available (no system to test with)" << std::endl;
    }

    // Test Canon EDSDK availability
    std::cout << "Testing Canon EDSDK availability..." << std::endl;
#ifdef EDSDK_AVAILABLE
    std::cout << "Canon EDSDK is available and linked" << std::endl;
    // Future: Initialize Canon camera module here
#else
    std::cout << "WARNING: Canon EDSDK not available" << std::endl;
    std::cout << "Canon camera functionality will be disabled" << std::endl;
    std::cout << "To enable Canon support:" << std::endl;
    std::cout << "  1. Download Canon EDSDK from developer.canon.com" << std::endl;
    std::cout << "  2. Run: ./scripts/setup_edsdk.sh <path-to-edsdk>" << std::endl;
    std::cout << "  3. Rebuild the project" << std::endl;
#endif

    std::cout << "Initialization complete. Press Ctrl+C to exit." << std::endl;

    // Main loop
    while (!should_exit) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    std::cout << "CanonMavlinkBridge shutting down..." << std::endl;
    return 0;
}