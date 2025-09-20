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

# Try to find PkgConfig, but make it optional for platforms that don't have it
find_package(PkgConfig QUIET)

# Include FetchContent for dependency management
include(FetchContent)

# Find JsonCpp (required by MAVSDK)
find_package(jsoncpp QUIET)

if(NOT jsoncpp_FOUND)
    message(STATUS "jsoncpp not found as system package, using FetchContent")

    FetchContent_Declare(
        jsoncpp
        GIT_REPOSITORY https://github.com/open-source-parsers/jsoncpp.git
        GIT_TAG 1.9.5
        GIT_SHALLOW TRUE
        GIT_PROGRESS TRUE
    )

    # Configure jsoncpp build options
    set(JSONCPP_WITH_TESTS OFF CACHE BOOL "Disable jsoncpp tests")
    set(JSONCPP_WITH_POST_BUILD_UNITTEST OFF CACHE BOOL "Disable jsoncpp post-build tests")
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build jsoncpp as static library")
    set(BUILD_STATIC_LIBS ON CACHE BOOL "Build jsoncpp as static library")

    FetchContent_MakeAvailable(jsoncpp)

    # Create JsonCpp::JsonCpp alias target that MAVSDK expects
    if(TARGET jsoncpp_static)
        add_library(JsonCpp::JsonCpp ALIAS jsoncpp_static)
        message(STATUS "Created JsonCpp::JsonCpp alias for jsoncpp_static")
    elseif(TARGET jsoncpp_lib)
        add_library(JsonCpp::JsonCpp ALIAS jsoncpp_lib)
        message(STATUS "Created JsonCpp::JsonCpp alias for jsoncpp_lib")
    else()
        message(FATAL_ERROR "JsonCpp target not found after FetchContent")
    endif()
else()
    message(STATUS "Found jsoncpp as system package")
    # Verify system package has the expected target
    if(NOT TARGET JsonCpp::JsonCpp)
        message(FATAL_ERROR "JsonCpp::JsonCpp target not found in system package")
    endif()
endif()

# Find TinyXML2 (required by MAVSDK)
find_package(tinyxml2 QUIET)

if(NOT tinyxml2_FOUND)
    message(STATUS "tinyxml2 not found as system package, using FetchContent")

    FetchContent_Declare(
        tinyxml2
        GIT_REPOSITORY https://github.com/leethomason/tinyxml2.git
        GIT_TAG 9.0.0
        GIT_SHALLOW TRUE
        GIT_PROGRESS TRUE
    )

    # Configure TinyXML2 build options
    set(tinyxml2_BUILD_TESTING OFF CACHE BOOL "Disable tinyxml2 tests")

    FetchContent_MakeAvailable(tinyxml2)

    # Create tinyxml2::tinyxml2 alias target that MAVSDK expects
    if(TARGET tinyxml2)
        add_library(tinyxml2::tinyxml2 ALIAS tinyxml2)
        message(STATUS "Created tinyxml2::tinyxml2 alias for tinyxml2")
    else()
        message(FATAL_ERROR "TinyXML2 target not found after FetchContent")
    endif()
else()
    message(STATUS "Found tinyxml2 as system package")
    # Verify system package has the expected target
    if(NOT TARGET tinyxml2::tinyxml2)
        message(FATAL_ERROR "tinyxml2::tinyxml2 target not found in system package")
    endif()
endif()

# Try to find MAVSDK as system package first
find_package(MAVSDK QUIET)

if(NOT MAVSDK_FOUND)
    message(STATUS "MAVSDK not found as system package, using FetchContent")

    FetchContent_Declare(
        MAVSDK
        GIT_REPOSITORY https://github.com/mavlink/MAVSDK.git
        GIT_TAG v1.4.16
        GIT_SHALLOW TRUE
        GIT_PROGRESS TRUE
    )

    # Configure MAVSDK build options for better performance
    set(SUPERBUILD OFF CACHE BOOL "Disable MAVSDK superbuild")
    set(BUILD_MAVSDK_SERVER OFF CACHE BOOL "Disable MAVSDK server")
    set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries")
    set(BUILD_TESTS OFF CACHE BOOL "Disable MAVSDK tests")

    # Enable required plugins
    set(PLUGINS "camera;ftp" CACHE STRING "Enable camera and ftp plugins")

    # Optional: disable curl for simpler builds
    set(ENABLE_CURL_TELEMETRY OFF CACHE BOOL "Disable curl telemetry")
    set(BUILD_WITHOUT_CURL ON CACHE BOOL "Build without curl")

    FetchContent_MakeAvailable(MAVSDK)

    # Verify core MAVSDK library is available
    if(NOT TARGET mavsdk)
        message(FATAL_ERROR "MAVSDK core library not available after FetchContent")
    endif()

    # Check for camera plugin (warn if not available)
    set(AVAILABLE_PLUGINS "")
    if(TARGET mavsdk_camera)
        list(APPEND AVAILABLE_PLUGINS "camera")
        message(STATUS "MAVSDK camera plugin available")
    else()
        message(WARNING "MAVSDK camera plugin not available - camera functionality will be limited")
    endif()

    # Check for FTP plugin (warn if not available)
    if(TARGET mavsdk_ftp)
        list(APPEND AVAILABLE_PLUGINS "ftp")
        message(STATUS "MAVSDK FTP plugin available")
    else()
        message(WARNING "MAVSDK FTP plugin not available - file transfer functionality will be limited")
    endif()

    # Set MAVSDK targets for FetchContent build
    set(MAVSDK_LIBRARIES mavsdk)
    if(TARGET mavsdk_camera)
        list(APPEND MAVSDK_LIBRARIES mavsdk_camera)
    endif()
    if(TARGET mavsdk_ftp)
        list(APPEND MAVSDK_LIBRARIES mavsdk_ftp)
    endif()

    message(STATUS "Using MAVSDK from FetchContent with available plugins: ${AVAILABLE_PLUGINS}")
else()
    message(STATUS "Found MAVSDK as system package")

    # Verify system package has required components
    if(NOT TARGET MAVSDK::mavsdk)
        message(FATAL_ERROR "MAVSDK::mavsdk target not found in system package")
    endif()

    # Check for camera plugin
    set(MAVSDK_SYSTEM_LIBRARIES "")
    if(TARGET MAVSDK::mavsdk_camera)
        list(APPEND MAVSDK_SYSTEM_LIBRARIES MAVSDK::mavsdk_camera)
        message(STATUS "Found MAVSDK camera plugin")
    else()
        message(WARNING "MAVSDK camera plugin not found in system package")
    endif()

    # Check for FTP plugin
    if(TARGET MAVSDK::mavsdk_ftp)
        list(APPEND MAVSDK_SYSTEM_LIBRARIES MAVSDK::mavsdk_ftp)
        message(STATUS "Found MAVSDK FTP plugin")
    else()
        message(WARNING "MAVSDK FTP plugin not found in system package")
    endif()

    set(MAVSDK_LIBRARIES MAVSDK::mavsdk ${MAVSDK_SYSTEM_LIBRARIES})
endif()

# Find yaml-cpp
if(PkgConfig_FOUND)
    pkg_check_modules(YAMLCPP yaml-cpp)
endif()

if(NOT YAMLCPP_FOUND)
    # Fall back to find_package for yaml-cpp
    find_package(yaml-cpp QUIET)
    if(yaml-cpp_FOUND)
        set(YAMLCPP_LIBRARIES yaml-cpp::yaml-cpp)
        set(YAMLCPP_INCLUDE_DIRS "")
        message(STATUS "Found yaml-cpp using find_package")
    else()
        # Fall back to FetchContent for yaml-cpp
        message(STATUS "yaml-cpp not found as system package, using FetchContent")

        FetchContent_Declare(
            yaml-cpp
            GIT_REPOSITORY https://github.com/jbeder/yaml-cpp.git
            GIT_TAG yaml-cpp-0.7.0
            GIT_SHALLOW TRUE
            GIT_PROGRESS TRUE
        )

        # Configure yaml-cpp build options
        set(YAML_CPP_BUILD_TESTS OFF CACHE BOOL "Disable yaml-cpp tests")
        set(YAML_CPP_BUILD_TOOLS OFF CACHE BOOL "Disable yaml-cpp tools")
        set(YAML_CPP_INSTALL OFF CACHE BOOL "Disable yaml-cpp install")
        set(YAML_BUILD_SHARED_LIBS OFF CACHE BOOL "Build yaml-cpp as static library")

        FetchContent_MakeAvailable(yaml-cpp)

        # Set yaml-cpp variables for compatibility
        if(TARGET yaml-cpp::yaml-cpp)
            set(YAMLCPP_LIBRARIES yaml-cpp::yaml-cpp)
            set(YAMLCPP_INCLUDE_DIRS "")
            message(STATUS "yaml-cpp successfully built from source via FetchContent")
        elseif(TARGET yaml-cpp)
            # Create alias if the target doesn't have namespace
            add_library(yaml-cpp::yaml-cpp ALIAS yaml-cpp)
            set(YAMLCPP_LIBRARIES yaml-cpp::yaml-cpp)
            set(YAMLCPP_INCLUDE_DIRS "")
            message(STATUS "yaml-cpp successfully built from source via FetchContent (created alias)")
        else()
            message(WARNING "yaml-cpp target not found after FetchContent. Configuration file parsing will be disabled.")
            set(YAMLCPP_LIBRARIES "")
            set(YAMLCPP_INCLUDE_DIRS "")
        endif()
    endif()
else()
    message(STATUS "Found yaml-cpp using pkg-config")
    # Ensure YAMLCPP_LIBRARIES is set correctly for pkg-config
    if(NOT YAMLCPP_LIBRARIES)
        set(YAMLCPP_LIBRARIES ${YAMLCPP_LINK_LIBRARIES})
    endif()
endif()

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