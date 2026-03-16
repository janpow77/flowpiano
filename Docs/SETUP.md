# SETUP.md — FlowPiano
Version 2.1

## Development Prerequisites

- Mac with supported macOS
- Xcode
- XcodeGen (`brew install xcodegen`)
- Apple Developer account for system-extension / signing work
- MIDI keyboard for validation
- at least one camera
- second camera recommended for full testing

## Project Generation

Generate the Xcode project from `project.yml`:

```bash
./scripts/generate_xcodeproj.sh
```

## First-Run Setup Flow

1. grant permissions
2. choose main camera
3. choose PiP camera if available
4. connect MIDI keyboard
5. test internal piano sound
6. position MIDI overlay
7. verify Studio Monitor notation visibility
8. install / validate virtual devices if available
