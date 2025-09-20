# Contributing to CanonMavlinkBridge

Thank you for your interest in contributing to CanonMavlinkBridge! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Development Environment:**
   - Linux system (Ubuntu 20.04+ recommended)
   - Git for version control
   - Basic knowledge of C++, CMake, and MAVLink

2. **Required Tools:**
   ```bash
   sudo apt update
   sudo apt install build-essential cmake pkg-config git
   sudo apt install libusb-1.0-0-dev libyaml-cpp-dev
   sudo apt install clang-format clang-tidy cppcheck
   ```

3. **Canon EDSDK:**
   - Download from Canon's developer website
   - Follow the setup instructions in the main README

### Setting Up Your Development Environment

1. **Fork and Clone:**
   ```bash
   git clone https://github.com/your-username/CanonMavlinkBridge.git
   cd CanonMavlinkBridge
   git remote add upstream https://github.com/original-repo/CanonMavlinkBridge.git
   ```

2. **Install Dependencies:**
   ```bash
   ./scripts/setup_dependencies.sh
   ```

3. **Build and Test:**
   ```bash
   ./scripts/build.sh Debug
   cd build && ctest
   ```

## Development Workflow

### Issue-Based Development

All development should start with a GitHub issue:

1. **Find or Create an Issue:**
   - Browse existing issues for something to work on
   - Create a new issue for bugs or feature requests
   - Comment on the issue to claim it

2. **Branch Naming:**
   ```bash
   # Feature branches
   git checkout -b feature/issue-123-add-live-view

   # Bug fix branches
   git checkout -b fix/issue-456-camera-disconnect

   # Documentation branches
   git checkout -b docs/issue-789-api-reference
   ```

3. **Keep Branches Updated:**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

### Commit Guidelines

- **Commit Messages:** Use the conventional commit format:
  ```
  type(scope): brief description

  Longer description if needed

  Fixes #123
  ```

- **Types:** `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`
- **Scopes:** `canon`, `mavlink`, `bridge`, `build`, `ci`, `docs`

- **Examples:**
  ```
  feat(canon): add live view streaming support
  fix(mavlink): handle camera disconnection gracefully
  docs(api): update camera control documentation
  test(integration): add end-to-end capture workflow test
  ```

## Coding Standards

### C++ Style Guide

We follow the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html) with some modifications:

1. **Formatting:**
   ```bash
   # Format all source files
   find src include -name "*.cpp" -o -name "*.h" | xargs clang-format -i
   ```

2. **Naming Conventions:**
   - Classes: `PascalCase` (e.g., `CanonCamera`)
   - Functions: `camelCase` (e.g., `takePicture`)
   - Variables: `snake_case` (e.g., `image_count`)
   - Constants: `kPascalCase` (e.g., `kMaxRetries`)
   - Member variables: `snake_case_` (e.g., `camera_state_`)

3. **File Organization:**
   - Header files: `.h` extension
   - Source files: `.cpp` extension
   - One class per header/source pair
   - Include guards or `#pragma once`

### Code Quality

1. **Static Analysis:**
   ```bash
   # Run clang-tidy
   clang-tidy src/**/*.cpp -- -I include

   # Run cppcheck
   cppcheck --enable=all src/
   ```

2. **Memory Management:**
   - Prefer smart pointers over raw pointers
   - Use RAII for resource management
   - Avoid memory leaks and dangling pointers

3. **Error Handling:**
   - Use exceptions for exceptional cases
   - Return error codes for expected failures
   - Log errors with appropriate severity levels

### Documentation Standards

1. **Code Documentation:**
   ```cpp
   /**
    * @brief Takes a picture with the connected Canon camera
    * @param settings Optional camera settings to apply
    * @return true if picture was taken successfully, false otherwise
    * @throws CameraException if camera is not connected
    */
   bool takePicture(const CameraSettings& settings = {});
   ```

2. **API Documentation:**
   - Use Doxygen-style comments
   - Document all public APIs
   - Include usage examples
   - Specify thread safety guarantees

## Testing

### Test Categories

1. **Unit Tests:**
   - Test individual functions and classes
   - Mock external dependencies (EDSDK, MAVSDK)
   - Located in `tests/unit/`

2. **Integration Tests:**
   - Test module interactions
   - Use test doubles for hardware
   - Located in `tests/integration/`

3. **Hardware Tests:**
   - Test with real Canon cameras
   - Test on target ARM platforms
   - Located in `tests/hardware/`

### Writing Tests

1. **Google Test Framework:**
   ```cpp
   #include <gtest/gtest.h>
   #include "canon/canon_camera.h"

   class CanonCameraTest : public ::testing::Test {
   protected:
       void SetUp() override {
           // Test setup
       }
   };

   TEST_F(CanonCameraTest, TakePictureSuccess) {
       // Test implementation
       EXPECT_TRUE(camera.takePicture());
   }
   ```

2. **Test Guidelines:**
   - One assertion per test when possible
   - Use descriptive test names
   - Test both success and failure cases
   - Clean up resources in test teardown

3. **Running Tests:**
   ```bash
   # Run all tests
   cd build && ctest

   # Run specific test suite
   cd build && ./tests/unit/canon_tests

   # Run with verbose output
   cd build && ctest --output-on-failure
   ```

### Code Coverage

Maintain >80% code coverage:

```bash
# Generate coverage report
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DCOVERAGE=ON
cmake --build build
cd build && ctest
gcov src/**/*.cpp
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
```

## Documentation

### Types of Documentation

1. **API Documentation:**
   - Generated from code comments using Doxygen
   - Available at `docs/api/`

2. **User Documentation:**
   - Installation guides
   - Configuration reference
   - Usage examples
   - Located in `docs/`

3. **Developer Documentation:**
   - Architecture overview
   - Design decisions
   - Build instructions
   - This file (CONTRIBUTING.md)

### Writing Documentation

1. **Markdown Standards:**
   - Use clear headings and structure
   - Include code examples
   - Link to related documentation
   - Keep line length under 100 characters

2. **Code Examples:**
   ```cpp
   // Always include complete, runnable examples
   #include "bridge/bridge_core.h"

   int main() {
       CanonMavlinkBridge bridge;
       bridge.initialize(config);
       bridge.run();
       return 0;
   }
   ```

## Submitting Changes

### Pull Request Process

1. **Before Creating a PR:**
   - Ensure all tests pass locally
   - Run code formatting and linting
   - Update documentation if needed
   - Rebase on latest main branch

2. **PR Description:**
   - Reference the related issue(s)
   - Describe what changes were made
   - Explain why the changes were necessary
   - Include testing instructions

3. **PR Checklist:**
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Tests added/updated
   - [ ] Documentation updated
   - [ ] No new warnings introduced
   - [ ] All CI checks pass

### Code Review Process

1. **Review Criteria:**
   - Code correctness and logic
   - Performance implications
   - Security considerations
   - Test coverage
   - Documentation quality

2. **Addressing Feedback:**
   - Respond to all review comments
   - Make requested changes
   - Push updates to the same branch
   - Re-request review when ready

3. **Merge Requirements:**
   - At least one approved review
   - All CI checks passing
   - Up-to-date with main branch
   - Squash commits before merge

## Release Process

### Version Management

We use [Semantic Versioning](https://semver.org/):
- MAJOR: Breaking API changes
- MINOR: New features, backwards compatible
- PATCH: Bug fixes, backwards compatible

### Release Workflow

1. **Feature Freeze:**
   - No new features
   - Bug fixes only
   - Update documentation

2. **Release Candidate:**
   - Create release branch
   - Deploy to staging
   - Community testing

3. **Release:**
   - Tag release
   - Generate changelog
   - Publish artifacts
   - Update documentation

## Getting Help

### Resources

- **Issues:** [GitHub Issues](https://github.com/your-username/CanonMavlinkBridge/issues)
- **Discussions:** [GitHub Discussions](https://github.com/your-username/CanonMavlinkBridge/discussions)
- **Documentation:** [Project Wiki](https://github.com/your-username/CanonMavlinkBridge/wiki)

### Communication

- **Questions:** Use GitHub Discussions for general questions
- **Bugs:** Create GitHub Issues with detailed reproduction steps
- **Features:** Discuss in Issues before implementing
- **Security:** Email maintainers privately for security issues

### Mentorship

New contributors are welcome! If you're new to:
- **Open Source:** Start with documentation or small bug fixes
- **C++:** Look for "good first issue" labels
- **MAVLink:** Check out the protocol documentation
- **Embedded Systems:** Start with simulation/testing

---

Thank you for contributing to CanonMavlinkBridge! Your efforts help make drone photography more accessible and reliable.