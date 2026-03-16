# FlowPiano Virtual Audio Driver Package Layout

This folder is the Windows-driver scaffold for the virtual microphone path.

## Expected Package Contents

- `FlowPianoVirtualMic.inf`
- `FlowPianoVirtualMic.sys`
- `FlowPianoVirtualMic.cat`
- `README.txt`
- `managed\*.json`

## Service Name

- `FlowPianoVirtualMic`

The managed Windows runtime currently probes this service name in the registry to determine whether a real virtual microphone driver is installed.

## Expected Managed Runtime Files

- `%APPDATA%\FlowPiano\Runtime\virtual-microphone-feed.json`
- `%APPDATA%\FlowPiano\Runtime\virtual-microphone-driver-feed.json`
- `%APPDATA%\FlowPiano\Runtime\virtual-audio-driver-manifest.json`

The future driver-side bridge or user-mode companion should consume the raw feed plus manifest, and can use the driver-bridge feed as a staged compatibility path until a fully native audio-routing path replaces it.

`INSTALL_DRIVER_PACKAGE.ps1` stages the current placeholder package layout into `out\FlowPianoVirtualMic`.
