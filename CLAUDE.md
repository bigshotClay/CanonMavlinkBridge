# CanonMavlinkBridge Design Document

## Project Overview

CanonMavlinkBridge is a Linux-based application that acts as a bridge between Canon cameras (via EDSDK) and MAVLink-enabled systems, specifically designed for drone companion computers (primarily ARM-based platforms).

## Key References

### MAVLink Camera Protocol Documentation
The primary reference is the MAVLink camera protocol documentation provided, which outlines:
- Camera control protocols and file transfer mechanisms  
- Three core messages: CAMERA_INFORMATION (ID 259), CAMERA_SETTINGS (ID 260), CAMERA_CAPTURE_STATUS (ID 262)
- DO_DIGICAM_CONTROL command (ID 203) for triggering
- File Transfer Protocol (FTP) for data exchange
- PX4 distance-based triggering capabilities

### Canon EDSDK Documentation  
The EDSDK 13.18.40 API provides:
- Linux support (ARM32/ARM64/x64)
- Camera control APIs (EdsOpenSession, EdsSendCommand, etc.)
- Property management (EdsGetPropertyData, EdsSetPropertyData)
- Live view capabilities (EdsDownloadEvfImage)
- File transfer functions (EdsDownload, EdsDownloadComplete)
- Asynchronous event handling

### MAVSDK C++ API
Located at: https://github.com/mavlink/MAVSDK
- Modern C++ interface for MAVLink
- Plugin-based architecture
- Supports camera control, FTP, and telemetry

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                     Companion Computer (ARM Linux)                │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    CanonMavlinkBridge                       │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │                                                             │ │
│  │  ┌──────────────┐    ┌──────────────┐   ┌───────────────┐ │ │
│  │  │ Canon Module │    │ Bridge Core  │   │MAVLink Module │ │ │
│  │  │              │◄───►│              │◄──►│               │ │ │
│  │  │  - EDSDK     │    │ - State Mgmt │   │ - MAVSDK      │ │ │
│  │  │  - Camera    │    │ - Command    │   │ - Protocol    │ │ │
│  │  │    Control   │    │   Mapping    │   │   Handler     │ │ │
│  │  │  - Image     │    │ - Event Queue│   │ - FTP Server  │ │ │
│  │  │    Transfer  │    │ - Config     │   │               │ │ │
│  │  └──────────────┘    └──────────────┘   └───────────────┘ │ │
│  │                                                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                               │                                   │
│                               ▼                                   │
│                    ┌──────────────────┐                          │
│                    │   File Storage    │                          │
│                    │  /tmp/camera/     │                          │
│                    └──────────────────┘                          │
│                                                                   │
└────────────┬──────────────────────────────────┬──────────────────┘
             │                                   │
             ▼                                   ▼
      ┌──────────────┐                   ┌──────────────┐
      │ Canon Camera │                   │   Autopilot  │
      │   (USB/PTP)  │                   │   (MAVLink)  │
      └──────────────┘                   └──────────────┘
```

## Core Components

### 1. Canon Module (`canon_module.h/cpp`)

**Responsibilities:**
- Initialize and manage EDSDK
- Handle camera connection/disconnection
- Execute camera commands
- Manage image capture and transfer
- Handle live view streaming

**Key Classes:**

```cpp
class CanonCamera {
public:
    // Lifecycle
    bool connect();
    void disconnect();
    bool isConnected() const;
    
    // Camera Control
    bool takePicture();
    bool setProperty(uint32_t propId, const void* data, size_t size);
    bool getProperty(uint32_t propId, void* data, size_t size);
    
    // Live View
    bool startLiveView();
    bool stopLiveView();
    std::optional<LiveViewFrame> getLiveViewFrame();
    
    // File Management
    std::vector<FileInfo> listFiles();
    bool downloadFile(const std::string& path, std::function<void(size_t)> progressCb);
    
    // Event Handlers
    void setObjectEventHandler(ObjectEventCallback cb);
    void setPropertyEventHandler(PropertyEventCallback cb);
    void setStateEventHandler(StateEventCallback cb);
    
private:
    EdsCameraRef camera_ = nullptr;
    EdsStreamRef stream_ = nullptr;
    std::atomic<bool> connected_{false};
    std::mutex mutex_;
};
```

### 2. MAVLink Module (`mavlink_module.h/cpp`)

**Responsibilities:**
- Handle MAVLink camera protocol messages
- Implement FTP server for file transfers
- Send camera status updates
- Process camera control commands

**Key Classes:**

```cpp
class MavlinkInterface {
public:
    // Lifecycle
    bool initialize(const std::string& connection_url);
    void shutdown();
    
    // Camera Protocol
    void sendCameraInformation(const CameraInfo& info);
    void sendCameraSettings(const CameraSettings& settings);
    void sendCaptureStatus(const CaptureStatus& status);
    
    // Command Handlers
    void registerDigicamControlHandler(DigicamControlCallback cb);
    void registerRequestMessageHandler(RequestMessageCallback cb);
    
    // FTP Server
    void startFtpServer(const std::string& root_path);
    void stopFtpServer();
    
    // Telemetry
    void subscribeToTriggerDistance(TriggerDistanceCallback cb);
    
private:
    std::shared_ptr<mavsdk::System> system_;
    std::shared_ptr<mavsdk::Camera> camera_plugin_;
    std::shared_ptr<mavsdk::Ftp> ftp_plugin_;
    std::atomic<bool> running_{false};
};
```

### 3. Bridge Core (`bridge_core.h/cpp`)

**Responsibilities:**
- Coordinate between Canon and MAVLink modules
- Map EDSDK properties to MAVLink messages
- Handle command translation
- Manage state synchronization
- Queue and process events

**Key Classes:**

```cpp
class CanonMavlinkBridge {
public:
    // Lifecycle
    bool initialize(const Config& config);
    void run();
    void shutdown();
    
    // Configuration
    struct Config {
        std::string mavlink_connection = "udp://127.0.0.1:14540";
        std::string storage_path = "/tmp/camera";
        bool enable_live_view = false;
        uint32_t status_rate_hz = 1;
        CameraCapabilities capabilities;
    };
    
private:
    // Modules
    std::unique_ptr<CanonCamera> canon_;
    std::unique_ptr<MavlinkInterface> mavlink_;
    
    // State Management
    struct CameraState {
        std::atomic<bool> recording{false};
        std::atomic<uint32_t> image_count{0};
        std::atomic<uint32_t> video_count{0};
        std::atomic<uint64_t> recording_time_ms{0};
        std::atomic<uint32_t> available_capacity_mb{0};
        std::mutex property_mutex;
        std::map<uint32_t, std::any> properties;
    } state_;
    
    // Command Mapping
    void handleDigicamControl(uint32_t param5, uint32_t param2, /*...*/);
    void handleSetCamTriggerDistance(float distance);
    
    // Property Mapping
    void mapCanonToMavlink();
    void syncCameraSettings();
    
    // Event Processing
    std::queue<Event> event_queue_;
    std::condition_variable event_cv_;
    void processEvents();
};
```

## Key Implementation Details

### Property Mapping

| Canon EDSDK Property | MAVLink Field | Notes |
|---------------------|---------------|-------|
| kEdsPropID_ProductName | CAMERA_INFORMATION.vendor_name | |
| kEdsPropID_BodyIDEx | CAMERA_INFORMATION.firmware_version | |
| kEdsPropID_ImageQuality | CAMERA_INFORMATION.resolution | Parse format |
| kEdsPropID_AEMode | CAMERA_SETTINGS.mode_id | Map shooting modes |
| kEdsPropID_Evf_Zoom | CAMERA_SETTINGS.zoom_level | Convert to percentage |
| kEdsPropID_FocusInfo | CAMERA_SETTINGS.focus_level | Extract focus position |
| kEdsPropID_AvailableShots | CAMERA_CAPTURE_STATUS.available_capacity | |

### Command Translation

| MAVLink Command | Canon EDSDK Call | Parameters |
|----------------|------------------|------------|
| DO_DIGICAM_CONTROL (param5=1) | EdsSendCommand(kEdsCameraCommand_PressShutterButton) | Trigger capture |
| DO_SET_CAM_TRIGG_DIST | Store distance trigger value | Enable distance-based capture |
| MAV_CMD_REQUEST_MESSAGE | Trigger status update | Send requested message |
| MAV_CMD_SET_MESSAGE_INTERVAL | Configure periodic updates | Set status rate |

### Event Flow

1. **Image Capture Flow:**
   ```
   MAVLink: DO_DIGICAM_CONTROL
   → Bridge: handleDigicamControl()
   → Canon: takePicture()
   → EDSDK: kEdsObjectEvent_DirItemRequestTransfer
   → Canon: downloadFile()
   → Storage: /tmp/camera/IMG_XXXX.JPG
   → MAVLink: FTP file available
   → MAVLink: CAMERA_CAPTURE_STATUS update
   ```

2. **Live View Flow:**
   ```
   MAVLink: Request live view
   → Bridge: Enable live view mode
   → Canon: startLiveView()
   → Loop: getLiveViewFrame()
   → MAVLink: Stream via custom protocol or RTSP
   ```

3. **Distance Trigger Flow:**
   ```
   MAVLink: Position update
   → Bridge: Calculate distance
   → If distance > threshold:
     → Canon: takePicture()
     → Follow capture flow
   ```

## Error Handling

### Canon Errors
- Map EDS_ERR_* codes to MAVLink COMMAND_ACK results
- Implement retry logic for transient errors
- Handle camera disconnection gracefully

### MAVLink Errors
- Timeout handling for command acknowledgments
- Connection loss recovery
- FTP transfer failure recovery

## Configuration File (`config.yaml`)

```yaml
# CanonMavlinkBridge Configuration
mavlink:
  connection: "udp://0.0.0.0:14540"
  system_id: 1
  component_id: 100
  
canon:
  auto_connect: true
  save_to: host  # host | camera | both
  image_quality: large_jpeg_fine
  
storage:
  path: "/tmp/camera"
  max_size_mb: 1000
  cleanup_on_start: false
  
features:
  live_view: false
  distance_trigger: true
  auto_focus: true
  
status:
  update_rate_hz: 1
  include_gps: true
  
logging:
  level: info  # debug | info | warning | error
  file: "/var/log/canon_mavlink_bridge.log"
```

## Build System (`CMakeLists.txt`)

```cmake
cmake_minimum_required(VERSION 3.16)
project(CanonMavlinkBridge)

set(CMAKE_CXX_STANDARD 17)

# Find packages
find_package(MAVSDK REQUIRED)
find_package(Threads REQUIRED)
find_package(yaml-cpp REQUIRED)

# EDSDK
set(EDSDK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/edsdk")
find_library(EDSDK_LIBRARY EDSDK PATHS ${EDSDK_ROOT}/lib)

# Sources
add_executable(canon_mavlink_bridge
    src/main.cpp
    src/bridge_core.cpp
    src/canon_module.cpp
    src/mavlink_module.cpp
    src/config.cpp
    src/utils.cpp
)

# Include directories
target_include_directories(canon_mavlink_bridge PRIVATE
    include
    ${EDSDK_ROOT}/include
)

# Link libraries
target_link_libraries(canon_mavlink_bridge
    ${EDSDK_LIBRARY}
    MAVSDK::mavsdk
    Threads::Threads
    yaml-cpp
)

# Install
install(TARGETS canon_mavlink_bridge
    RUNTIME DESTINATION bin
)
```

## Testing Strategy

### Unit Tests
- Mock EDSDK functions for Canon module testing
- Mock MAVSDK for MAVLink module testing
- Test property mapping logic
- Test command translation

### Integration Tests
- Camera simulator for EDSDK
- SITL (Software In The Loop) for MAVLink
- End-to-end capture workflow
- FTP transfer verification

### Hardware Tests
- Canon camera models compatibility matrix
- ARM platform testing (Raspberry Pi, Jetson Nano)
- Performance benchmarks
- Stress testing (continuous capture, large files)

## Development Phases

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] Project setup and build system
- [ ] Basic Canon module with camera connection
- [ ] Basic MAVLink module with connection
- [ ] Simple bridge core with event loop

### Phase 2: Basic Functionality (Week 3-4)
- [ ] Image capture command handling
- [ ] Camera information reporting
- [ ] File storage management
- [ ] Basic FTP server integration

### Phase 3: Advanced Features (Week 5-6)
- [ ] Live view streaming
- [ ] Distance-based triggering
- [ ] Property synchronization
- [ ] Status reporting

### Phase 4: Polish & Testing (Week 7-8)
- [ ] Error handling and recovery
- [ ] Performance optimization
- [ ] Documentation
- [ ] Deployment scripts

## Deployment

### Systemd Service (`canon-mavlink-bridge.service`)

```ini
[Unit]
Description=Canon MAVLink Bridge
After=network.target

[Service]
Type=simple
User=drone
ExecStart=/usr/local/bin/canon_mavlink_bridge -c /etc/canon-mavlink-bridge/config.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Docker Support (`Dockerfile`)

```dockerfile
FROM arm64v8/ubuntu:20.04

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libusb-1.0-0 \
    libyaml-cpp-dev

COPY . /app
WORKDIR /app

RUN mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc)

CMD ["/app/build/canon_mavlink_bridge"]
```

## Key Considerations

### Performance
- Use asynchronous I/O for file transfers
- Implement proper threading for Canon events
- Buffer live view frames appropriately
- Minimize latency in command processing

### Reliability
- Implement watchdog timer
- Handle camera power cycles
- Recover from USB disconnections
- Queue commands during camera busy states

### Security
- Validate MAVLink message sources
- Sanitize file paths for FTP
- Limit resource usage (memory, disk)
- Log security-relevant events

### Compatibility
- Support multiple Canon camera models
- Handle different EDSDK versions
- Work with various MAVLink implementations
- Support ARM32/ARM64 architectures

## Resources and References

1. MAVLink Camera Protocol V2: https://mavlink.io/en/services/camera.html
2. MAVLink FTP Protocol: https://mavlink.io/en/services/ftp.html
3. MAVSDK Documentation: https://mavsdk.mavlink.io/
4. Canon EDSDK Forum: https://developercommunity.usa.canon.com/
5. PX4 Camera Trigger: https://docs.px4.io/main/en/peripherals/camera.html

## Next Steps for Implementation

1. **Environment Setup:**
   - Install MAVSDK on target platform
   - Set up EDSDK for Linux ARM
   - Configure development environment

2. **Start with Canon Module:**
   - Test basic camera connection
   - Verify EDSDK functionality on ARM
   - Implement error handling

3. **Implement MAVLink Module:**
   - Test MAVSDK connection
   - Verify message handling
   - Implement camera protocol

4. **Build Bridge Core:**
   - Start with simple command mapping
   - Add state management
   - Implement event processing

5. **Iterative Testing:**
   - Test each component in isolation
   - Integrate incrementally
   - Validate with real hardware

---

This design document provides a comprehensive foundation for implementing the CanonMavlinkBridge. The modular architecture allows for incremental development and testing, while the detailed specifications ensure compatibility with both Canon EDSDK and MAVLink protocols.

## Program Management

### Project Structure and Organization

The CanonMavlinkBridge project follows an incremental, milestone-driven development approach using GitHub for project tracking, issue management, and collaborative development.

### GitHub Repository Setup

#### Repository Structure
```
CanonMavlinkBridge/
├── .github/
│   ├── workflows/          # CI/CD workflows
│   ├── ISSUE_TEMPLATE/     # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/                   # Documentation
│   ├── api/               # API documentation
│   ├── architecture/      # Architecture diagrams
│   └── hardware/          # Hardware compatibility
├── src/                   # Source code
│   ├── canon/            # Canon module
│   ├── mavlink/          # MAVLink module
│   ├── bridge/           # Bridge core
│   └── utils/            # Utilities
├── include/              # Header files
├── tests/                # Test suites
│   ├── unit/            # Unit tests
│   ├── integration/     # Integration tests
│   └── hardware/        # Hardware tests
├── third_party/          # External dependencies
│   ├── edsdk/           # Canon EDSDK
│   └── mavsdk/          # MAVSDK (if not system-installed)
├── scripts/              # Build/deployment scripts
├── config/               # Configuration files
├── CMakeLists.txt        # Build configuration
├── README.md             # Project overview
├── CONTRIBUTING.md       # Contribution guidelines
├── LICENSE               # Project license
└── CLAUDE.md            # This design document
```

#### GitHub Features Configuration

1. **Repository Settings:**
   - Enable Issues, Wiki, Projects
   - Set default branch to `main`
   - Enable branch protection rules
   - Require PR reviews before merge
   - Enable automatic deletion of head branches

2. **Labels for Issue Management:**
   ```
   # Type Labels
   - type:bug          # Bug reports
   - type:feature      # New features
   - type:enhancement  # Improvements to existing features
   - type:documentation # Documentation updates
   - type:testing      # Testing improvements
   - type:ci           # CI/CD improvements

   # Priority Labels
   - priority:critical # Critical issues blocking development
   - priority:high     # High priority items
   - priority:medium   # Medium priority items
   - priority:low      # Low priority items

   # Component Labels
   - component:canon   # Canon module related
   - component:mavlink # MAVLink module related
   - component:bridge  # Bridge core related
   - component:build   # Build system related
   - component:testing # Testing infrastructure

   # Status Labels
   - status:blocked    # Blocked by dependencies
   - status:in-review  # Under review
   - status:ready      # Ready for implementation
   - status:wip        # Work in progress

   # Milestone Labels
   - milestone:m1      # Milestone 1 tasks
   - milestone:m2      # Milestone 2 tasks
   - milestone:m3      # Milestone 3 tasks
   - milestone:m4      # Milestone 4 tasks
   ```

### Development Milestones

#### Milestone 1: Foundation Setup (Week 1-2)
**Goal:** Establish development environment and basic project structure

**Deliverables:**
- [ ] GitHub repository with complete structure
- [ ] CI/CD pipeline setup (GitHub Actions)
- [ ] MAVSDK integration and build system
- [ ] Canon EDSDK integration
- [ ] Basic CMake configuration
- [ ] Development environment documentation
- [ ] Contribution guidelines

**Acceptance Criteria:**
- Project builds successfully on Linux ARM64
- All dependencies are properly resolved
- CI pipeline passes basic build tests
- Documentation is complete and accessible

#### Milestone 2: Core Module Implementation (Week 3-4)
**Goal:** Implement basic Canon and MAVLink modules

**Deliverables:**
- [ ] Canon module with camera connection
- [ ] MAVLink module with basic communication
- [ ] Unit test framework setup
- [ ] Basic error handling and logging
- [ ] Configuration file parsing

**Acceptance Criteria:**
- Canon camera can be detected and connected
- MAVLink communication is established
- Unit tests achieve >80% code coverage
- All modules handle disconnection gracefully

#### Milestone 3: Bridge Integration (Week 5-6)
**Goal:** Implement bridge core and basic camera operations

**Deliverables:**
- [ ] Bridge core with event loop
- [ ] Image capture functionality
- [ ] File storage management
- [ ] Basic MAVLink camera protocol support
- [ ] Integration tests

**Acceptance Criteria:**
- End-to-end image capture workflow functional
- MAVLink camera information messages sent correctly
- Files stored and accessible via FTP
- Integration tests pass on target hardware

#### Milestone 4: Production Ready (Week 7-8)
**Goal:** Complete feature set and production deployment

**Deliverables:**
- [ ] Live view streaming
- [ ] Distance-based triggering
- [ ] Production deployment scripts
- [ ] Performance optimization
- [ ] Hardware compatibility testing
- [ ] User documentation

**Acceptance Criteria:**
- All specified features implemented and tested
- Performance meets requirements
- Deployment scripts work on target platforms
- Documentation complete for end users

### Issue Templates

#### Bug Report Template
```markdown
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] Brief description'
labels: 'type:bug'
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment:**
- OS: [e.g. Ubuntu 20.04 ARM64]
- Canon Camera Model: [e.g. EOS R5]
- EDSDK Version: [e.g. 13.18.40]
- MAVSDK Version: [e.g. 1.4.16]

**Logs**
If applicable, add logs to help explain your problem.

**Additional context**
Add any other context about the problem here.
```

#### Feature Request Template
```markdown
---
name: Feature Request
about: Suggest an idea for this project
title: '[FEATURE] Brief description'
labels: 'type:feature'
assignees: ''
---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is.

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions.

**Additional context**
Add any other context or screenshots about the feature request.

**Implementation considerations**
- Impact on existing features
- Hardware requirements
- Performance implications
```

### Project Boards and Workflow

#### GitHub Projects Setup
1. **Development Board**: Kanban-style board with columns:
   - Backlog
   - Ready for Development
   - In Progress
   - In Review
   - Testing
   - Done

2. **Release Planning Board**: Milestone-focused board:
   - Milestone 1 Tasks
   - Milestone 2 Tasks
   - Milestone 3 Tasks
   - Milestone 4 Tasks
   - Future Enhancements

#### Workflow Process
1. **Issue Creation**: All work starts with a GitHub issue
2. **Issue Triage**: Weekly triage to assign labels, milestones, and priority
3. **Branch Creation**: Feature branches from main (`feature/issue-number-description`)
4. **Development**: Work on feature branch with regular commits
5. **Testing**: Ensure all tests pass locally
6. **Pull Request**: Create PR with description linking to issue
7. **Code Review**: At least one reviewer approval required
8. **CI/CD**: Automated tests must pass
9. **Merge**: Squash and merge to main
10. **Deployment**: Automatic deployment to staging environment

### Dependency Management Strategy

#### MAVSDK Integration
```cmake
# Option 1: System package (preferred for CI)
find_package(MAVSDK REQUIRED)

# Option 2: Git submodule (for development)
if(NOT MAVSDK_FOUND)
    include(FetchContent)
    FetchContent_Declare(
        MAVSDK
        GIT_REPOSITORY https://github.com/mavlink/MAVSDK.git
        GIT_TAG v1.4.16
    )
    FetchContent_MakeAvailable(MAVSDK)
endif()
```

#### Canon EDSDK Integration
```cmake
# EDSDK as third-party dependency
set(EDSDK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/edsdk")

# Verify EDSDK is available for target architecture
if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    set(EDSDK_ARCH "arm64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
    set(EDSDK_ARCH "arm")
else()
    set(EDSDK_ARCH "x64")
endif()

find_library(EDSDK_LIBRARY
    NAMES EDSDK
    PATHS "${EDSDK_ROOT}/lib/${EDSDK_ARCH}"
    REQUIRED
)
```

#### Package Management
- **vcpkg**: For cross-platform C++ dependencies
- **Conan**: Alternative package manager if needed
- **System packages**: Use distribution packages when available
- **Git submodules**: For dependencies requiring custom builds

### CI/CD Pipeline

#### GitHub Actions Workflow
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-20.04]
        arch: [x64, arm64]

    runs-on: ${{ matrix.os }}

    steps:
    - uses: actions/checkout@v3

    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y cmake build-essential libusb-1.0-0-dev

    - name: Setup MAVSDK
      run: |
        wget https://github.com/mavlink/MAVSDK/releases/download/v1.4.16/mavsdk_1.4.16_ubuntu20.04_amd64.deb
        sudo dpkg -i mavsdk_1.4.16_ubuntu20.04_amd64.deb

    - name: Configure CMake
      run: cmake -B build -DCMAKE_BUILD_TYPE=Release

    - name: Build
      run: cmake --build build --config Release

    - name: Test
      run: cd build && ctest --output-on-failure

    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: canon-mavlink-bridge-${{ matrix.arch }}
        path: build/canon_mavlink_bridge
```

### Quality Assurance

#### Code Quality Standards
- **Static Analysis**: clang-tidy, cppcheck
- **Code Coverage**: gcov/lcov with >80% target
- **Memory Safety**: AddressSanitizer, Valgrind
- **Code Style**: clang-format with Google C++ style
- **Documentation**: Doxygen for API documentation

#### Testing Strategy
1. **Unit Tests**: Google Test framework
2. **Integration Tests**: Custom test harness
3. **Hardware Tests**: Automated testing on target platforms
4. **Performance Tests**: Benchmarking with realistic workloads

### Release Management

#### Versioning Strategy
- **Semantic Versioning**: MAJOR.MINOR.PATCH
- **Release Branches**: `release/v1.0.0`
- **Hotfix Branches**: `hotfix/v1.0.1`
- **Pre-release**: Alpha/Beta versions for testing

#### Release Process
1. **Feature Freeze**: No new features, bug fixes only
2. **Release Candidate**: Deploy to staging environment
3. **Testing**: Comprehensive testing on all target platforms
4. **Documentation**: Update user documentation and changelog
5. **Release**: Tag and create GitHub release
6. **Distribution**: Package for various platforms

### Communication and Collaboration

#### Documentation Standards
- **README.md**: Project overview and quick start
- **CONTRIBUTING.md**: Detailed contribution guidelines
- **CHANGELOG.md**: Version history and changes
- **API Documentation**: Generated from code comments
- **Architecture Documentation**: High-level design decisions

#### Team Communication
- **GitHub Discussions**: Design discussions and Q&A
- **Issue Comments**: Progress updates and technical discussions
- **Pull Request Reviews**: Code quality and knowledge sharing
- **Project Wiki**: Long-form documentation and tutorials

### Risk Management

#### Technical Risks
1. **EDSDK Compatibility**: Limited access to Canon SDK documentation
   - Mitigation: Early hardware testing, community engagement

2. **ARM Platform Performance**: Resource constraints on embedded systems
   - Mitigation: Performance profiling, optimization cycles

3. **MAVLink Protocol Changes**: Updates to camera protocol specification
   - Mitigation: Version pinning, backwards compatibility testing

#### Project Risks
1. **Dependency Availability**: External dependencies may become unavailable
   - Mitigation: Vendor multiple dependencies, maintain forks

2. **Hardware Access**: Limited access to target hardware platforms
   - Mitigation: Emulation, community hardware testing program

3. **Resource Constraints**: Limited development time/resources
   - Mitigation: Incremental delivery, community contributions

This program management framework ensures systematic development, quality assurance, and successful delivery of the CanonMavlinkBridge project.
