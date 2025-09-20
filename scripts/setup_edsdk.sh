#!/bin/bash

# Canon EDSDK Setup Script
# This script helps set up the Canon EDSDK for the CanonMavlinkBridge project

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EDSDK_DIR="${PROJECT_ROOT}/third_party/edsdk"

echo "Canon EDSDK Setup for CanonMavlinkBridge"
echo "========================================"
echo

# Check if EDSDK is already installed
if [ -f "${EDSDK_DIR}/include/EDSDK.h" ]; then
    echo "✓ EDSDK appears to be already installed in ${EDSDK_DIR}"
    echo "  If you want to reinstall, remove the directory first:"
    echo "  rm -rf ${EDSDK_DIR}"
    exit 0
fi

echo "The Canon EDSDK is proprietary software that must be downloaded"
echo "separately from Canon's developer website."
echo
echo "Steps to install EDSDK:"
echo "1. Visit: https://developercommunity.usa.canon.com/"
echo "2. Create an account and accept the license terms"
echo "3. Download EDSDK 13.18.40 for Linux"
echo "4. Extract the downloaded archive"
echo "5. Run this script with the path to the extracted EDSDK"
echo

# Check if user provided EDSDK path
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-extracted-edsdk>"
    echo
    echo "Example:"
    echo "  $0 ~/Downloads/EDSDK_13_18_40_Linux"
    exit 1
fi

EDSDK_SOURCE="$1"

# Validate EDSDK source directory
if [ ! -d "${EDSDK_SOURCE}" ]; then
    echo "Error: Directory ${EDSDK_SOURCE} does not exist"
    exit 1
fi

if [ ! -f "${EDSDK_SOURCE}/include/EDSDK.h" ]; then
    echo "Error: EDSDK.h not found in ${EDSDK_SOURCE}/include/"
    echo "Please ensure you're pointing to the correct EDSDK directory"
    exit 1
fi

echo "Installing EDSDK from ${EDSDK_SOURCE}..."

# Create EDSDK directory structure
mkdir -p "${EDSDK_DIR}"
mkdir -p "${EDSDK_DIR}/include"
mkdir -p "${EDSDK_DIR}/lib"

# Copy headers
echo "Copying headers..."
cp -r "${EDSDK_SOURCE}/include/"* "${EDSDK_DIR}/include/"

# Copy libraries for all architectures
echo "Copying libraries..."
for arch in x64 arm arm64; do
    if [ -d "${EDSDK_SOURCE}/lib/${arch}" ]; then
        echo "  - ${arch} libraries"
        mkdir -p "${EDSDK_DIR}/lib/${arch}"
        cp -r "${EDSDK_SOURCE}/lib/${arch}/"* "${EDSDK_DIR}/lib/${arch}/"
    else
        echo "  - ${arch} libraries not found (skipping)"
    fi
done

# Copy license and documentation
if [ -f "${EDSDK_SOURCE}/license.txt" ]; then
    cp "${EDSDK_SOURCE}/license.txt" "${EDSDK_DIR}/"
fi

if [ -d "${EDSDK_SOURCE}/doc" ]; then
    cp -r "${EDSDK_SOURCE}/doc" "${EDSDK_DIR}/"
fi

echo
echo "✓ EDSDK installation completed!"
echo
echo "Directory structure:"
tree "${EDSDK_DIR}" 2>/dev/null || find "${EDSDK_DIR}" -type f | head -10

echo
echo "You can now build the CanonMavlinkBridge project:"
echo "  mkdir build && cd build"
echo "  cmake .."
echo "  make"