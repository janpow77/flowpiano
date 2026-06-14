# FlowPiano

macOS-Anwendung für Klavierunterricht und -Performance in Videokonferenzen. Liefert eine virtuelle Kamera und ein virtuelles Mikrofon, eine bewegliche MIDI-Keyboard-Overlay, eine interne Klavier-Sound-Engine und einen lokalen Studio-Monitor. Kernregel: strikte Trennung zwischen **Public Output** (Target A, für das Publikum) und **Studio Monitor** (Target B, nur lokal) — kein lokaler Layer (Notation, Meter, Diagnostik) darf in Target A gelangen.

Das Repo ist ein Multi-Plattform-Monorepo mit drei eigenständigen Bäumen:
- `Sources/` + `Tests/` — macOS-App (Swift, SwiftPM/Xcode), die Referenzimplementierung
- `web/` — React/TypeScript-Web-Variante (Harmony Trainer + virtuelles Piano)
- `windows/` — nach C# portierte Windows-Variante (.NET 8 / WPF)

## Tech-Stack

- **macOS:** Swift 5.10, Swift Package Manager (`Package.swift`) + XcodeGen (`project.yml`), Deployment-Target macOS 13. SwiftUI-App, `AVAudioEngine`/`AVAudioUnitSampler` (interne Piano-Engine), CoreMIDI, System-Extensions für virtuelle Kamera/Audio. Gebündelte SoundFont-Bank `GeneralUser GS v1.471.sf2` unter `Sources/AudioEngine/Resources/`.
- **Web:** React 19, TypeScript 5.9, Vite 8, Tailwind CSS 4, Zustand (State), Tone.js (Audio), Web MIDI API. Tests mit Vitest + Testing Library/jsdom, Lint mit ESLint 9 / typescript-eslint.
- **Windows:** C# / .NET 8, WPF (`FlowPiano.Windows.App`), WinMM (MIDI/Synth), Media Foundation / WMI (Kamera). Native Scaffolds (C++/CMake, INF) für virtuelle Kamera/Audio. Tests mit xUnit.
- **CI:** GitHub Actions (`.github/workflows/ci.yml`), nur manuell (`workflow_dispatch`) oder auf `v*`-Tags.

## Setup & Befehle

### macOS (Swift)
```bash
# Xcode-Projekt aus project.yml erzeugen (benötigt: brew install xcodegen)
./scripts/generate_xcodeproj.sh

# Build & Tests via SwiftPM (wie in CI)
swift package resolve
swift build -Xswiftc -suppress-warnings
swift test --filter FlowPianoUnitTests
swift test --filter FlowPianoIntegrationTests
swift test --filter FlowPianoUITests
```

### Web (`web/`)
```bash
npm install
npm run dev        # Vite Dev-Server
npm run build      # tsc -b && vite build
npm run preview    # gebautes Bundle preview
npm run lint       # eslint .
npm test           # vitest run
npm run test:watch # vitest (watch)
```

### Windows (`windows/`, nur auf Windows; PowerShell-Skripte)
```powershell
dotnet restore FlowPiano.Windows.sln
dotnet build  FlowPiano.Windows.sln --configuration Release --no-restore
dotnet test   FlowPiano.Windows.sln --configuration Release --no-build
# Wrapper-Skripte: scripts/build_managed.ps1, scripts/test_managed.ps1,
# scripts/build_windows_workspace.ps1, scripts/verify_runtime_artifacts.ps1
```

## Struktur

```
Sources/        macOS-Swift-Module (je Modul ein SwiftPM-Target/Framework)
  App/          SwiftUI-Einstieg: FlowPianoApp, FlowPianoAppModel, ContentView, Platform-Bridge
  FlowPianoCore/  zentraler Aggregat-Layer (Session-Koordination), hängt von allen Engines ab
  VideoEngine/  Kamera-Capture & Session-Steuerung
  MIDIEngine/   MIDI-Discovery, Parsing, Reconnect
  AudioEngine/  interne Piano-Engine, Sprach-Mic-Mix, SF2-Resource
  NotationEngine/ Notenrendering (nur lokal / Studio Monitor)
  LayoutEngine/ Scene-Graph & Target-spezifische Sichtbarkeit (Public vs. Studio)
  OverlayEngine/ MIDI-Keyboard-Overlay
  HarmonyTrainer/ Musiktheorie: Akkorderkennung, funktionale Harmonik, Übungen/Progressionen
  StudioMonitor/ lokale Monitor-Präsentation (Notation, Meter, Diagnostik)
  Diagnostics/  Latenz-/Status-Diagnostik
  Settings/, Persistence/  Konfiguration & Layout-Persistenz
  VirtualCameraExtension/, VirtualAudioDriver/  System-Extensions (Public-Output-Publikation)
Tests/          Unit/, Integration/, UI/ (XCTest)
Config/         Info.plists, Entitlements, xcconfig
Docs/           SPEC, ARCHITECTURE, AGENTS, SETUP, TESTING, RELEASE, TROUBLESHOOTING
scripts/        generate_xcodeproj.sh
web/src/        React-App: domain/ (Theorie-Kern), components/, hooks/, utils/, __tests__/
windows/src/    .NET-Tree: FlowPiano.Windows.Core (Domain), .Platform (WinMM/MF), .App (WPF)
graphify-out/   generierte Code-Graph-Artefakte (graph.json, manifest.json)
```

Zentrale Module laut Code-Graph: `FlowPianoCore` (höchste Knotendichte, Aggregations-Layer), `HarmonyTrainer`/`MusicTheory` (Theorie-Kern, in allen drei Plattformen gespiegelt), `LayoutEngine` (Public/Studio-Sichtbarkeitsmodell), `VideoEngine` und `Diagnostics`.

## Konventionen

- **Trennungsregel (höchste Test-Priorität):** Kein nur-lokaler Layer darf in den Public Output (Target A) gelangen — siehe `Docs/AGENTS.md`, `Docs/TESTING.md`, `LayoutEngine`. Tests dazu: `Tests/Unit/LayoutVisibilityTests.swift`.
- **macOS:** ein Modul pro `Sources/<Modul>/`-Verzeichnis; Build mit `-Xswiftc -suppress-warnings` (CI-Konvention). Bundle-IDs `com.example.FlowPiano.*` (vor Release anpassen).
- **Web:** TypeScript, ESLint (`web/eslint.config.js`); reine Theorie-Logik liegt in `web/src/domain/` und ist per Vitest in `web/src/__tests__/domain/` abgedeckt.
- **Windows:** `Nullable` + `ImplicitUsings` aktiviert (`windows/Directory.Build.props`); Domain-Logik in `.Core`, plattformspezifische APIs isoliert in `.Platform`.
- **Dokumentation/Specs** sind in `Docs/` versioniert und für Agenten bindend (`Docs/AGENTS.md`).
