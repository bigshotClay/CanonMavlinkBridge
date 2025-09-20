cmake_minimum_required(VERSION 3.16)
project(CanonMavlinkBridge VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Compiler options
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -Wall -Wextra")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# Enable testing
enable_testing()

# Find required packages
find_package(Threads REQUIRED)
find_package(PkgConfig REQUIRED)

# Try to find MAVSDK as system package first
find_package(MAVSDK QUIET)

if(NOT MAVSDK_FOUND)
    message(STATUS "MAVSDK not found as system package, using FetchContent")
    include(FetchContent)

    FetchContent_Declare(
        MAVSDK
        GIT_REPOSITORY https://github.com/mavlink/MAVSDK.git
        GIT_TAG v1.4.16
    )

    # Configure MAVSDK options
    set(SUPERBUILD OFF)
    set(BUILD_MAVSDK_SERVER OFF)
    set(BUILD_SHARED_LIBS ON)

    FetchContent_MakeAvailable(MAVSDK)

    # Set MAVSDK targets
    set(MAVSDK_LIBRARIES mavsdk mavsdk_camera mavsdk_ftp)
else()
    message(STATUS "Found MAVSDK as system package")
    set(MAVSDK_LIBRARIES MAVSDK::mavsdk MAVSDK::mavsdk_camera MAVSDK::mavsdk_ftp)
endif()

# Find yaml-cpp
pkg_check_modules(YAMLCPP REQUIRED yaml-cpp)

# EDSDK Configuration
set(EDSDK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/edsdk")

# Detect target architecture for EDSDK
if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    set(EDSDK_ARCH "arm64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
    set(EDSDK_ARCH "arm")
else()
    set(EDSDK_ARCH "x64")
endif()

# Find EDSDK library
find_library(EDSDK_LIBRARY
    NAMES EDSDK
    PATHS "${EDSDK_ROOT}/lib/${EDSDK_ARCH}"
    NO_DEFAULT_PATH
)

if(NOT EDSDK_LIBRARY)
    message(WARNING "EDSDK library not found. Please install EDSDK to third_party/edsdk/")
    message(WARNING "See third_party/README.md for installation instructions")
    set(EDSDK_LIBRARY "")  # Allow build to continue for CI/development
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${EDSDK_ROOT}/include
    ${YAMLCPP_INCLUDE_DIRS}
)

# Source files
set(CANON_SOURCES
    src/canon/canon_camera.cpp
    src/canon/canon_errors.cpp
)

set(MAVLINK_SOURCES
    src/mavlink/mavlink_interface.cpp
    src/mavlink/camera_protocol.cpp
    src/mavlink/ftp_server.cpp
)

set(BRIDGE_SOURCES
    src/bridge/bridge_core.cpp
    src/bridge/command_mapper.cpp
    src/bridge/property_mapper.cpp
    src/bridge/event_processor.cpp
)

set(UTILS_SOURCES
    src/utils/config.cpp
    src/utils/logger.cpp
    src/utils/file_utils.cpp
)

set(ALL_SOURCES
    src/main.cpp
    ${CANON_SOURCES}
    ${MAVLINK_SOURCES}
    ${BRIDGE_SOURCES}
    ${UTILS_SOURCES}
)

# Create main executable
add_executable(canon_mavlink_bridge ${ALL_SOURCES})

# Link libraries
target_link_libraries(canon_mavlink_bridge
    ${MAVSDK_LIBRARIES}
    ${EDSDK_LIBRARY}
    ${YAMLCPP_LIBRARIES}
    Threads::Threads
)

# Compiler definitions
target_compile_definitions(canon_mavlink_bridge PRIVATE
    PROJECT_VERSION="${PROJECT_VERSION}"
    $<$<CONFIG:Debug>:DEBUG>
)

# Install rules
install(TARGETS canon_mavlink_bridge
    RUNTIME DESTINATION bin
)

install(FILES config/config.yaml
    DESTINATION etc/canon-mavlink-bridge
)

# Create systemd service file
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/scripts/canon-mavlink-bridge.service.in
    ${CMAKE_CURRENT_BINARY_DIR}/canon-mavlink-bridge.service
    @ONLY
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/canon-mavlink-bridge.service
    DESTINATION /etc/systemd/system
    OPTIONAL
)

# Testing
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

# Documentation
find_package(Doxygen QUIET)
if(DOXYGEN_FOUND)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in
        ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
        @ONLY
    )

    add_custom_target(docs
        ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Generating API documentation with Doxygen"
    )
endif()

# Package configuration
set(CPACK_PACKAGE_NAME "canon-mavlink-bridge")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "MAVLink bridge for Canon cameras on companion computers")
set(CPACK_PACKAGE_VENDOR "CanonMavlinkBridge Contributors")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")

include(CPack)