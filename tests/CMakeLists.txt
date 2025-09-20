# CanonMavlinkBridge Tests CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

# Enable testing
enable_testing()

# Find Google Test
find_package(GTest QUIET)

if(NOT GTest_FOUND)
    message(STATUS "GTest not found as system package, using FetchContent")

    include(FetchContent)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG release-1.12.1
        GIT_SHALLOW TRUE
        GIT_PROGRESS TRUE
    )

    # Configure GTest build options
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(googletest)

    # Create aliases for compatibility
    add_library(GTest::gtest ALIAS gtest)
    add_library(GTest::gtest_main ALIAS gtest_main)

    message(STATUS "GTest successfully built from source via FetchContent")
else()
    message(STATUS "Found GTest as system package")
endif()

# Add test directories
add_subdirectory(unit)
add_subdirectory(integration)

# Hardware tests are optional (require actual hardware)
if(BUILD_HARDWARE_TESTS)
    add_subdirectory(hardware)
endif()