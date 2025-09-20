# CanonMavlinkBridge

[![CI/CD Pipeline](https://github.com/your-username/CanonMavlinkBridge/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/CanonMavlinkBridge/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-supported-blue.svg)](https://github.com/your-username/CanonMavlinkBridge/pkgs/container/canonmavlinkbridge)

A Linux-based application that acts as a bridge between Canon cameras (via EDSDK) and MAVLink-enabled systems, specifically designed for drone companion computers (primarily ARM-based platforms).

## Features

- **MAVLink Camera Protocol**: Full implementation of MAVLink camera protocol v2
- **Canon EDSDK Integration**: Support for Canon cameras via the official EDSDK
- **Cross-Platform**: Supports x64, ARM32, and ARM64 architectures
- **Real-time Communication**: Low-latency camera control and status reporting
- **File Transfer**: FTP-based image and video transfer via MAVLink
- **Distance Triggering**: Automatic image capture based on GPS distance
- **Live View**: Camera live view streaming capabilities
- **Configuration**: YAML-based configuration with runtime parameter updates

## Supported Hardware

### Canon Cameras
- Canon EOS R series (R5, R6, RP, etc.)
- Canon EOS DSLR series (5D Mark IV, 6D Mark II, etc.)
- Canon PowerShot series (select models with EDSDK support)

### Companion Computers
- Raspberry Pi 4/5 (ARM64)
- NVIDIA Jetson Nano/Xavier (ARM64)
- Intel NUC (x64)
- Custom ARM-based flight controllers

### Autopilots
- PX4 (v1.12+)
- ArduPilot (v4.0+)
- Any MAVLink v2 compatible autopilot

## Quick Start

### Prerequisites

- Linux system (Ubuntu 20.04+ recommended)
- Canon camera with USB connection
- MAVLink-compatible autopilot
- Canon EDSDK (see [Installation Guide](#installation))

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/CanonMavlinkBridge.git
   cd CanonMavlinkBridge
   ```

2. **Install dependencies:**
   ```bash
   sudo apt update
   sudo apt install build-essential cmake pkg-config libusb-1.0-0-dev libyaml-cpp-dev
   ```

3. **Install MAVSDK:**
   ```bash
   # For Ubuntu 20.04/22.04
   wget https://github.com/mavlink/MAVSDK/releases/download/v1.4.16/mavsdk_1.4.16_ubuntu20.04_amd64.deb
   sudo dpkg -i mavsdk_1.4.16_ubuntu20.04_amd64.deb
   ```

4. **Setup Canon EDSDK:**
   ```bash
   # Download EDSDK from Canon's developer website
   # Then run:
   ./scripts/setup_edsdk.sh /path/to/extracted/edsdk
   ```

5. **Build the project:**
   ```bash
   ./scripts/build.sh
   ```

6. **Run the application:**
   ```bash
   ./build/canon_mavlink_bridge -c config/config.yaml
   ```

## Configuration

The application uses a YAML configuration file. Here's a basic example:

```yaml
mavlink:
  connection: "udp://0.0.0.0:14540"
  system_id: 1
  component_id: 100

canon:
  auto_connect: true
  save_to: host
  image_quality: large_jpeg_fine

storage:
  path: "/tmp/camera"
  max_size_mb: 1000

features:
  live_view: false
  distance_trigger: true
  auto_focus: true

logging:
  level: info
  file: "/var/log/canon_mavlink_bridge.log"
```

See [Configuration Guide](docs/configuration.md) for detailed options.

## Usage

### Basic Camera Control

The bridge responds to standard MAVLink camera commands:

```bash
# Trigger photo capture
mavlink.py --target-system 1 --target-component 100 \
  --command MAV_CMD_DO_DIGICAM_CONTROL --param5 1

# Set trigger distance (capture every 10 meters)
mavlink.py --target-system 1 --target-component 100 \
  --command MAV_CMD_DO_SET_CAM_TRIGG_DIST --param1 10

# Request camera information
mavlink.py --target-system 1 --target-component 100 \
  --command MAV_CMD_REQUEST_MESSAGE --param1 259
```

### Integration with Ground Control Stations

The bridge is compatible with:
- **QGroundControl**: Full camera control and file download
- **Mission Planner**: Basic camera control and triggering
- **MAVProxy**: Command-line camera control

### Docker Deployment

```bash
# Pull the latest image
docker pull ghcr.io/your-username/canonmavlinkbridge:latest

# Run with camera access
docker run -d \
  --name canon-bridge \
  --device /dev/bus/usb \
  -p 14540:14540/udp \
  -v /tmp/camera:/tmp/camera \
  ghcr.io/your-username/canonmavlinkbridge:latest
```

## Development

### Project Structure

```
CanonMavlinkBridge/
├── src/                    # Source code
│   ├── canon/             # Canon EDSDK integration
│   ├── mavlink/           # MAVLink protocol handling
│   ├── bridge/            # Core bridge logic
│   └── utils/             # Utilities and helpers
├── include/               # Header files
├── tests/                 # Test suites
├── docs/                  # Documentation
└── scripts/               # Build and deployment scripts
```

### Building from Source

```bash
# Debug build
./scripts/build.sh Debug

# Release build
./scripts/build.sh Release

# Run tests
cd build && ctest --output-on-failure
```

### Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Documentation

- [Architecture Overview](docs/architecture.md)
- [API Reference](docs/api/README.md)
- [Hardware Compatibility](docs/hardware/README.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Performance Guide](docs/performance.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/your-username/CanonMavlinkBridge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/CanonMavlinkBridge/discussions)
- **Documentation**: [Project Wiki](https://github.com/your-username/CanonMavlinkBridge/wiki)

## Acknowledgments

- [Canon Inc.](https://www.canon.com/) for the EDSDK
- [MAVLink Project](https://mavlink.io/) for the communication protocol
- [MAVSDK](https://github.com/mavlink/MAVSDK) for the C++ MAVLink library
- [PX4](https://px4.io/) and [ArduPilot](https://ardupilot.org/) for autopilot integration

## Roadmap

- [ ] Support for Canon's Camera Connect API
- [ ] RTMP/RTSP live streaming
- [ ] Advanced image processing pipelines
- [ ] Multi-camera support
- [ ] Web-based configuration interface
- [ ] ROS2 integration

---

**Note**: This project requires the Canon EDSDK, which is proprietary software that must be obtained separately from Canon. Please ensure you comply with Canon's license terms when using the EDSDK.