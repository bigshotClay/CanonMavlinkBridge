# Third Party Dependencies

This directory contains external dependencies for the CanonMavlinkBridge project.

## EDSDK (Canon Camera SDK)

The Canon EDSDK must be downloaded separately from Canon's developer website:
https://developercommunity.usa.canon.com/

### Installation Steps:

1. Download EDSDK 13.18.40 for Linux
2. Extract to `third_party/edsdk/`
3. Ensure the following structure:
   ```
   third_party/edsdk/
   ├── include/
   │   └── EDSDK.h
   └── lib/
       ├── x64/
       ├── arm/
       └── arm64/
   ```

### License Note:
The EDSDK is proprietary software from Canon and is not included in this repository.
You must agree to Canon's license terms to use the EDSDK.

## MAVSDK

MAVSDK can be installed via:
1. System package manager (preferred)
2. CMake FetchContent (automatic download)
3. Manual installation from https://github.com/mavlink/MAVSDK

The build system will automatically handle MAVSDK integration based on availability.