# FlowPiano

FlowPiano is a macOS application for piano teaching and performance in videoconferencing.

It combines:

- configurable face and keyboard cameras
- a MIDI keyboard overlay
- an internal classical piano engine
- speech microphone mixing
- a virtual camera
- a virtual microphone
- a local-only studio monitor with notation and diagnostics

## Current Repository State

The repository now contains:

- a bundled `GeneralUser GS v1.471.sf2` piano bank under `Sources/AudioEngine/Resources/`
- macOS runtime bridges for:
  - camera discovery
  - MIDI discovery and note input
  - permission status
  - internal piano playback through `AVAudioEngine` and `AVAudioUnitSampler`
- JSON publication artifacts for the public scene and virtual microphone feed
- an `xcodegen` project spec in `project.yml`

For a commercial release, review the bundled sound bank license carefully or switch the app to the macOS system sound bank only.

To generate a full Xcode project on macOS:

```bash
brew install xcodegen
./scripts/generate_xcodeproj.sh
```

## Key Product Rule

FlowPiano has two outputs:

- **Public Output** for the audience
- **Studio Monitor** for the local user

The Studio Monitor may show notation, meters, and diagnostics.
The Public Output must not.

See the documents in `Docs/`.
