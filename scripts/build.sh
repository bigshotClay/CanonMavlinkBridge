#!/bin/bash

# Build script for CanonMavlinkBridge
# Handles dependency checking and builds the project

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
BUILD_TYPE="${1:-Release}"

echo "CanonMavlinkBridge Build Script"
echo "==============================="
echo "Build type: ${BUILD_TYPE}"
echo

# Check dependencies
echo "Checking dependencies..."

# Check for CMake
if ! command -v cmake &> /dev/null; then
    echo "Error: CMake is required but not installed"
    exit 1
fi
echo "✓ CMake found: $(cmake --version | head -1)"

# Check for C++ compiler
if ! command -v g++ &> /dev/null && ! command -v clang++ &> /dev/null; then
    echo "Error: C++ compiler (g++ or clang++) is required"
    exit 1
fi
echo "✓ C++ compiler found"

# Check for pkg-config
if ! command -v pkg-config &> /dev/null; then
    echo "Warning: pkg-config not found, some dependencies may not be detected"
fi

# Check for EDSDK
EDSDK_DIR="${PROJECT_ROOT}/third_party/edsdk"
if [ ! -f "${EDSDK_DIR}/include/EDSDK.h" ]; then
    echo "Warning: Canon EDSDK not found in ${EDSDK_DIR}"
    echo "         Run scripts/setup_edsdk.sh to install EDSDK"
    echo "         Build will continue but EDSDK features will be disabled"
fi

# Detect architecture
ARCH=$(uname -m)
echo "✓ Target architecture: ${ARCH}"

# Create build directory
echo
echo "Configuring build..."
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Configure with CMake
cmake .. \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DBUILD_TESTING=ON

echo
echo "Building..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo
echo "✓ Build completed successfully!"
echo
echo "Output binary: ${BUILD_DIR}/canon_mavlink_bridge"
echo
echo "To run tests:"
echo "  cd ${BUILD_DIR} && ctest"
echo
echo "To install:"
echo "  cd ${BUILD_DIR} && sudo make install"