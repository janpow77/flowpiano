# FlowPiano Native Windows Scaffolds

This directory contains the native Windows pieces that cannot be completed honestly from the managed WPF/.NET layer alone.

## Included

- `FlowPiano.VirtualCamera.Source`
  - CMake-based C++ DLL scaffold
  - shared CLSID that matches the managed virtual-camera bridge manifest
  - explicit DLL export definition plus registry-template generation helper
- `FlowPiano.VirtualCamera.Source/REGISTER_CAMERA_SOURCE.ps1`
  - generates a `.reg` template for manual COM registration review
- `FlowPiano.VirtualAudio.Driver`
  - INF/package layout scaffold for a future signed virtual microphone driver
  - service name aligned with the managed bridge status detection
- `FlowPiano.VirtualAudio.Driver/INSTALL_DRIVER_PACKAGE.ps1`
  - stages a placeholder driver package folder with INF plus managed bridge files
- `CMakePresets.json`
  - local configure/build presets for Visual Studio 2022 on x64

## How This Connects To The Managed App

The managed Windows runtime writes bridge manifests and feed files under:

- `%APPDATA%\FlowPiano\Runtime\public-output-scene.json`
- `%APPDATA%\FlowPiano\Runtime\camera-capture-session.json`
- `%APPDATA%\FlowPiano\Runtime\virtual-camera-registration.json`
- `%APPDATA%\FlowPiano\Runtime\virtual-camera-bridge.json`
- `%APPDATA%\FlowPiano\Runtime\virtual-microphone-feed.json`
- `%APPDATA%\FlowPiano\Runtime\virtual-audio-driver-manifest.json`
- `%APPDATA%\FlowPiano\Runtime\virtual-microphone-driver-feed.json`

The native projects in this folder are the next layer that must consume those files on a real Windows machine.

`windows/scripts/prepare_native_bridges.ps1` stages those runtime files into this folder so the native projects can be wired against stable filenames during Windows-only implementation work.

`windows/scripts/build_native_scaffolds.ps1` then configures/builds the camera DLL scaffold and stages the audio-driver placeholder package.

## Current Status

- The C++ virtual-camera source is a scaffold, not a working `IMFMediaSource` implementation yet.
- The audio-driver folder is packaging scaffolding, not a signed or installable driver bundle yet.
- These files exist so the next Windows-only implementation pass can build on stable IDs, names, and expected runtime paths.
