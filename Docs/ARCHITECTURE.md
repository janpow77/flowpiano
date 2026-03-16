# ARCHITECTURE.md — FlowPiano
Version 2.1

## Runtime Domains

1. device capture
2. musical event processing
3. audio generation and mixing
4. video compositing
5. dual-output presentation
6. virtual device publication

## Module Responsibilities

- `VideoEngine`: capture and camera session control
- `MIDIEngine`: MIDI discovery, parsing, reconnect
- `NotationEngine`: local-only staff rendering
- `AudioEngine`: internal piano, speech mic, optional external routing
- `LayoutEngine`: scene graph and target-specific visibility
- `StudioMonitor`: local-only monitor presentation
- `VirtualCameraExtension`: public output publication
- `VirtualAudioDriver`: mixed audio publication
