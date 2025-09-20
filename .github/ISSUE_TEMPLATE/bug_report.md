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
- Platform: [e.g. Raspberry Pi 4, Jetson Nano, x86_64 PC]
- OS: [e.g. Ubuntu 20.04 ARM64]
- Canon Camera Model: [e.g. EOS R5, EOS R6 Mark II]
- EDSDK Version: [e.g. 13.19.10]
- MAVSDK Version: [e.g. 1.4.16]
- CanonMavlinkBridge Version: [e.g. v1.0.0 or commit hash]
- Connection Type: [e.g. USB-C, USB-A, Network]

**Logs**
Please include relevant logs. You can get logs by:
```bash
# Application logs
journalctl -u canon-mavlink-bridge -f

# System logs for USB devices
dmesg | grep -i usb

# Debug logs (if enabled)
./canon_mavlink_bridge --verbose --log-level debug
```

**Screenshots/Videos**
If applicable, add screenshots or videos to help explain your problem.

**Workaround**
If you found a temporary workaround, please describe it.

**Additional context**
Add any other context about the problem here.