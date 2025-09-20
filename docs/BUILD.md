# Building CanonMavlinkBridge

This document describes how to build CanonMavlinkBridge on different platforms with various dependency configurations.

## Build Dependencies

### Required Dependencies
- CMake 3.16 or higher
- C++17 compatible compiler (GCC 8+, Clang 10+, MSVC 2019+)
- Git (for downloading dependencies)

### Platform-Specific Dependencies

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    libusb-1.0-0-dev \
    pkg-config
```

#### macOS
```bash
# Using Homebrew
brew install cmake git

# pkg-config is optional but recommended
brew install pkg-config yaml-cpp
```

#### Fedora/RHEL
```bash
sudo dnf install -y \
    gcc-c++ \
    cmake \
    git \
    libusb1-devel \
    pkgconfig
```

## MAVSDK Dependency Management

The build system supports two methods for obtaining MAVSDK:

### 1. System Package (Preferred)
If MAVSDK is installed as a system package, it will be used automatically:

```bash
# Ubuntu/Debian
sudo apt-get install libmavsdk-dev

# Or build from source and install system-wide
git clone https://github.com/mavlink/MAVSDK.git
cd MAVSDK
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

### 2. FetchContent (Automatic Fallback)
If no system package is found, CMake will automatically download and build MAVSDK:

- Downloads MAVSDK v1.4.16 from GitHub
- Uses shallow clone for faster downloads
- Builds only required components
- Includes camera and FTP plugins when available

## Build Configuration

### Basic Build
```bash
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### Debug Build
```bash
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc)
```

### Advanced Options

#### Force FetchContent for MAVSDK
```bash
cmake .. -DMAVSDK_ROOT=/nonexistent
```

#### Disable Specific Features
```bash
cmake .. \
    -DBUILD_TESTING=OFF \
    -DBUILD_WITHOUT_CURL=ON \
    -DENABLE_CURL_TELEMETRY=OFF
```

#### Custom Install Prefix
```bash
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
```

## Dependency Details

### MAVSDK Plugins
The build system automatically detects and configures these MAVSDK plugins:

- **mavsdk**: Core library (required)
- **mavsdk_camera**: Camera protocol support
- **mavsdk_ftp**: File Transfer Protocol support

If plugins are not available, the build will continue with warnings, and functionality will be limited.

### YAML Configuration Support
Configuration file parsing uses yaml-cpp with multiple detection methods:

1. **With pkg-config**: Uses `pkg-config` to find system yaml-cpp
2. **CMake find_package**: Falls back to CMake's find_package
3. **FetchContent (Automatic)**: Downloads and builds yaml-cpp v0.7.0 if not found

#### Installing yaml-cpp (Optional)
If you prefer to use a system-installed version instead of the automatic FetchContent:

```bash
# Ubuntu/Debian
sudo apt-get install libyaml-cpp-dev

# macOS
brew install yaml-cpp

# Fedora/RHEL
sudo dnf install yaml-cpp-devel
```

The build system will automatically detect and use the system package if available, otherwise it will download and build yaml-cpp automatically.

### Canon EDSDK
The Canon EDSDK must be manually installed:

```bash
# Download EDSDK from Canon
# Extract to third_party/edsdk/
mkdir -p third_party/edsdk
# Copy lib/ and include/ directories
```

See `third_party/README.md` for detailed installation instructions.

## Cross-Compilation

### ARM64 (Raspberry Pi, Jetson)
```bash
# On host system with ARM64 toolchain
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=path/to/arm64-toolchain.cmake \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64
```

### ARM32
```bash
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=path/to/arm-toolchain.cmake \
    -DCMAKE_SYSTEM_PROCESSOR=arm
```

## Troubleshooting

### Common Issues

#### "Could NOT find PkgConfig"
This is not fatal. The build will continue using alternative dependency detection.

#### "MAVSDK camera plugin not available"
This is a warning. The core functionality will work, but camera features may be limited.

#### "yaml-cpp not found"
This issue should no longer occur as yaml-cpp is automatically downloaded and built via FetchContent. If you still encounter this issue, you can install yaml-cpp manually:
```bash
# Ubuntu/Debian
sudo apt-get install libyaml-cpp-dev

# macOS
brew install yaml-cpp
```

#### Build fails with "No SOURCES given"
This means the source files haven't been created yet. This is expected during initial project setup.

### Build Performance

#### Faster MAVSDK Downloads
The build uses shallow clones and disables unnecessary components:
- `GIT_SHALLOW TRUE`: Only downloads latest commit
- `BUILD_TESTS OFF`: Skips test compilation
- `BUILD_WITHOUT_CURL ON`: Reduces dependencies

#### Parallel Builds
Use multiple cores for faster compilation:
```bash
make -j$(nproc)  # Linux
make -j$(sysctl -n hw.ncpu)  # macOS
```

## Platform Support

### Tested Platforms
- Ubuntu 20.04, 22.04 (x64, ARM64)
- macOS 11+ (x64, ARM64)
- Debian 11+ (ARM32, ARM64)

### Target Platforms
- Raspberry Pi OS (ARM32, ARM64)
- NVIDIA Jetson (ARM64)
- Generic Linux distributions

## Docker Support

Build in a controlled environment:
```bash
docker build -t canon-mavlink-bridge .
docker run --rm -v $(pwd):/app canon-mavlink-bridge
```

See `Dockerfile` for platform-specific build configurations.