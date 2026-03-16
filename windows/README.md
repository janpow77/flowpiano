# FlowPiano Windows

This directory contains a separate Windows project tree for FlowPiano.

It is not a direct port of the Swift/macOS runtime. The domain logic and release rules were ported into C#, and the Windows-specific APIs are isolated behind a separate platform project.

## Included Now

- `FlowPiano.Windows.Core`
  - layout separation rules
  - MIDI / audio / notation / diagnostics domain logic
  - setup checklist
  - runtime snapshot coordinator
- `FlowPiano.Windows.App`
  - WPF shell for the Windows variant
  - live WinMM MIDI + Windows synth bridge for the internal piano path
  - live Windows camera discovery with preview fallback when no real device is found
  - generated preview artifacts for Public Output, Studio Monitor, and virtual microphone state
  - same public-vs-studio visibility model
- `FlowPiano.Windows.Platform`
  - native `winmm.dll` services for MIDI input and internal piano output
  - composite video discovery path with Media-Foundation availability probe plus WMI fallback
  - HTML/SVG/JSON preview artifacts and a capture-session manifest under the runtime directory
  - Media-Foundation virtual-camera support probe plus separate scene feed, bridge feed, and registration manifests/scripts
  - virtual-audio driver bridge manifests with separate raw feed and driver-bridge feed artifacts
- `FlowPiano.Windows.Tests`
  - target-separation and startup smoke tests
- `native/`
  - CMake/INF scaffolds for the native virtual-camera and virtual-audio continuation path
  - stable staging targets for the managed runtime feeds and manifests

## Build On Windows

1. Install Visual Studio 2022 or newer with .NET desktop development.
2. Install the .NET 8 SDK.
3. Open `FlowPiano.Windows.sln`.
4. Restore packages and build.
5. Run the app once so `%APPDATA%\FlowPiano\Runtime` is populated.
6. If you want to continue with the native virtual-device layer, run `scripts/prepare_native_bridges.ps1`.

## Local Scripts

- `scripts/build_managed.ps1`
  - restores and builds `FlowPiano.Windows.sln`
- `scripts/test_managed.ps1`
  - runs the xUnit suite for the Windows tree
- `scripts/build_native_scaffolds.ps1`
  - stages managed bridge files, configures CMake, builds the virtual-camera scaffold, and stages the virtual-audio driver package folder
- `scripts/build_windows_workspace.ps1`
  - combined entry point for managed build, tests, and native scaffold build
- `scripts/verify_runtime_artifacts.ps1`
  - checks whether the expected runtime JSON/SVG/HTML artifacts exist under `%APPDATA%\FlowPiano\Runtime`

## Important Limits

- Live MIDI input and internal piano output now use the native WinMM path when the app is run on Windows.
- Live camera discovery is now present through a composite path, but actual Media Foundation frame capture is still not wired in; when discovery fails, the UI stays on a preview camera profile.
- The repo now generates stable raw feeds, bridge descriptors, and registration manifests for the virtual-camera and virtual-audio paths, but real registration still depends on a native Media Foundation source and a signed audio driver package.
- Public Output and Studio Monitor previews are now written as runtime artifacts together with a camera capture-session manifest, but they are still preview renders, not a native Windows virtual camera feed.
- The same bundled SF2 is still copied into the app output, but the current Windows runtime renders through the system synth path, not through a custom SF2 sampler yet.
