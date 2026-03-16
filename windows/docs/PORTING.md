# Windows Porting Notes

This Windows variant uses the same product rules as the macOS tree:

- strict separation between `Public Output` and `Studio Monitor`
- movable MIDI overlay
- internal piano-first routing
- diagnostics and setup checklist
- virtual-device publication paths as explicit subsystems

## Recommended Windows Stack

- UI shell: WPF on .NET 8
- shared business logic: `FlowPiano.Windows.Core`
- camera capture: Media Foundation
- virtual camera publication: Windows virtual camera APIs
- MIDI baseline: WinMM abstraction, with an extension path for Windows MIDI Services
- audio render / speech input: WASAPI
- virtual microphone: dedicated Windows audio driver path

## Why The Runtime Is Split

The existing Swift code mixes product logic with Apple platform frameworks. On Windows, the common rules are reusable, but the device and publication APIs are not.

The split in this folder is:

- `Core`: platform-neutral product rules
- `Platform`: Windows integration contracts
- `App`: operator UI
- `Tests`: regression coverage for target separation and setup logic

## Official References

- Microsoft virtual camera docs:
  - https://learn.microsoft.com/windows/win32/api/mfvirtualcamera/
- Windows MIDI Services overview:
  - https://devblogs.microsoft.com/windows-music-dev/the-new-windows-midi-services-what-it-is-and-why-it-matters/
- WinMM MIDI input APIs:
  - https://learn.microsoft.com/windows/win32/multimedia/midi-reference
- Windows audio driver sample guidance:
  - https://learn.microsoft.com/windows-hardware/drivers/audio/sysvad-virtual-audio-device-driver-sample

## Next Windows-Specific Steps

1. Replace the current Media-Foundation availability probe + WMI fallback with a real `IWindowsVideoCaptureService` backed by Media Foundation frame capture.
2. Replace the current virtual-camera bridge descriptor with a real Media Foundation COM media source registered under the generated source CLSID and consuming `public-output-scene.json` / `camera-capture-session.json`.
3. Swap the SVG/HTML preview artifact path for a native composition path that feeds the Windows virtual camera directly.
4. Replace the current Windows system-synth fallback with a dedicated SF2 sampler or WASAPI render engine if bundled-bank parity is required.
5. Turn the virtual microphone bridge manifest plus raw JSON feed into a real Windows audio driver publication path and add packaging/signing for both virtual-device components.
