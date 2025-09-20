# Multi-stage Dockerfile for CanonMavlinkBridge
# Supports both AMD64 and ARM64 architectures

# Build stage
FROM ubuntu:22.04 AS builder

# Avoid interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    curl \
    wget \
    libusb-1.0-0-dev \
    libyaml-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

# Set architecture-specific variables
ARG TARGETARCH
ENV MAVSDK_VERSION=1.4.16

# Install MAVSDK
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        # Build MAVSDK from source for ARM64 \
        git clone --depth 1 --branch v${MAVSDK_VERSION} https://github.com/mavlink/MAVSDK.git && \
        cd MAVSDK && \
        cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DSUPERBUILD=OFF && \
        cmake --build build -j$(nproc) && \
        cmake --install build; \
    else \
        # Use pre-built package for AMD64 \
        wget -q https://github.com/mavlink/MAVSDK/releases/download/v${MAVSDK_VERSION}/mavsdk_${MAVSDK_VERSION}_ubuntu$(lsb_release -rs | tr -d .)_amd64.deb && \
        dpkg -i mavsdk_*.deb || apt-get install -f -y; \
    fi

# Copy source code
WORKDIR /app
COPY . .

# Build the application
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    && cmake --build build --config Release -j$(nproc)

# Runtime stage
FROM ubuntu:22.04 AS runtime

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libusb-1.0-0 \
    libyaml-cpp0.7 \
    && rm -rf /var/lib/apt/lists/*

# Create application user
RUN useradd -r -s /bin/false -d /app drone

# Create required directories
RUN mkdir -p /tmp/camera /var/log /etc/canon-mavlink-bridge \
    && chown -R drone:drone /tmp/camera /var/log

# Copy application binary
COPY --from=builder /app/build/canon_mavlink_bridge /usr/local/bin/
COPY --from=builder /app/config/config.yaml /etc/canon-mavlink-bridge/

# Copy MAVSDK libraries
COPY --from=builder /usr/local/lib/libmavsdk* /usr/local/lib/

# Update library cache
RUN ldconfig

# Set permissions
RUN chmod +x /usr/local/bin/canon_mavlink_bridge

# Switch to application user
USER drone

# Set working directory
WORKDIR /app

# Expose MAVLink port
EXPOSE 14540/udp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep canon_mavlink_bridge || exit 1

# Default command
CMD ["/usr/local/bin/canon_mavlink_bridge", "-c", "/etc/canon-mavlink-bridge/config.yaml"]