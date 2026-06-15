# Architektur — flowpiano

_Automatisch generiert von graphify-kira aus dem Code-Graphen. Nicht von Hand editieren — wird beim nächsten Lauf überschrieben._

**Umfang:** 1836 Knoten, 3596 Kanten, 20 größere Module, 2 zirkuläre Abhängigkeiten.

## Modulkarte

- **Core Audio Engine** (86): `FlowPianoCore.swift`, `VirtualAudioDriverTests.swift`
- **Diagnostics Coordinator** (84): `DiagnosticsAndCoordinator.cs`
- **App Configuration** (63): `FlowPianoApp.swift`, `FlowPianoAppModel.swift`, `ObservableObject`, `FlowPianoUITests.swift`, `App.xaml.cs`
- **Chord Detection** (61): `HarmonyTrainer.cs`
- **UI Event Handling** (59): `MainWindowViewModel.cs`, `INotifyPropertyChanged`, `IDisposable`, `WinMmAudioRuntimeService.cs`, `IWindowsAudioRuntimeService`
- **Audio Runtime Errors** (56): `PlatformAudioRuntime.swift`, `Error`, `MIDIEngine.swift`, `VideoEngine.swift`, `VirtualAudioDriver.swift`
- **Layout Engine** (49): `FlowPianoCore.swift`, `LayoutEngine.swift`, `VirtualCameraExtensionTests.swift`
- **Chord Qualities** (48): `diatonicAnalysis.test.ts`, `progression.test.ts`, `ProgressionSelector.tsx`, `chordQuality.ts`, `chordType.ts`
- **Session Timer** (46): `App.tsx`, `ProgressionSelector.tsx`, `SessionTimer.tsx`, `StatsDisplay.tsx`, `ChordFeedback.tsx`
- **Video Engine** (44): `MusicTheory.swift`, `Int`
- **Harmony Trainer Tests** (43): `CaseIterable`, `VideoEngine.swift`
- **Error Diagnostics** (42): `ContentView.swift`, `FlowPianoAppModel.swift`, `FlowPianoCore.swift`, `HarmonyTrainerTests.swift`
- **Harmony Trainer Tests** (42): `Diagnostics.swift`
- **Platform Bridge** (39): `HarmonyTrainerTests.cs`
- **Windows Integration** (38): `FlowPianoPlatformBridge.swift`
- **Music Theory** (37): `package.json`
- **Project Dependencies** (37): `WindowsIntegrationPlan.cs`
- **Audio Engine** (35): `AudioEngine.swift`
- **Windows Runtime Host** (35): `FlowPianoWindowsRuntimeHost.cs`
- **MIDI Interop** (33): `WinMmInterop.cs`

## Zentrale Bausteine (God Nodes)

_Hohe Zentralität ist nicht automatisch ein Defekt (zentrale Stores/Modelle sind oft legitim). Konkrete Refactoring-Prioritäten siehe Optimierungs-Report._

- `Codable` — Grad 70 (ein 70/aus 0)
- `Fact (windows/tests/FlowPiano.Windows.Tests/HarmonyTrainerTests.cs)` — Grad 36 (ein 36/aus 0)
- `Equatable` — Grad 59 (ein 59/aus 0)
- `index.ts (web/src/domain/index.ts)` — Grad 83 (ein 0/aus 83)
- `FlowPianoAppModel (Sources/App/FlowPianoAppModel.swift)` — Grad 47 (ein 11/aus 36)
- `.refresh() (Sources/App/FlowPianoAppModel.swift)` — Grad 23 (ein 23/aus 0)
- `.RefreshSnapshot() (windows/src/FlowPiano.Windows.Core/DiagnosticsAndCoordinator.cs)` — Grad 35 (ein 29/aus 6)
- `FlowPianoSessionCoordinator (windows/src/FlowPiano.Windows.Core/DiagnosticsAndCoordinator.cs)` — Grad 57 (ein 1/aus 56)
- `.refreshSnapshot() (Sources/FlowPianoCore/FlowPianoCore.swift)` — Grad 32 (ein 27/aus 5)
- `String` — Grad 28 (ein 28/aus 0)

## Schnittstellen / Brücken (Betweenness)

- `.refreshSnapshot() (Sources/FlowPianoCore/FlowPianoCore.swift)` — Betweenness 0.000
- `FlowPianoRuntimeSnapshot (Sources/FlowPianoCore/FlowPianoCore.swift)` — Betweenness 0.000
- `FlowPianoAppModel (Sources/App/FlowPianoAppModel.swift)` — Betweenness 0.000
- `.RefreshSnapshot() (windows/src/FlowPiano.Windows.Core/DiagnosticsAndCoordinator.cs)` — Betweenness 0.000
- `PitchClass (Sources/HarmonyTrainer/MusicTheory.swift)` — Betweenness 0.000
- `SetupChecklistItem (Sources/FlowPianoCore/FlowPianoCore.swift)` — Betweenness 0.000
- `SetupStep (Sources/FlowPianoCore/FlowPianoCore.swift)` — Betweenness 0.000
- `FlowPianoUITests (Tests/UI/FlowPianoUITests.swift)` — Betweenness 0.000
- `.BuildReport() (windows/src/FlowPiano.Windows.Core/DiagnosticsAndCoordinator.cs)` — Betweenness 0.000
- `progressionTemplate.ts (web/src/domain/progressionTemplate.ts)` — Betweenness 0.000

## Zirkuläre Abhängigkeiten

Es gibt **2** nicht-triviale Zyklen (starke Zusammenhangskomponenten) — Kandidaten zum Auflösen (Dependency-Inversion).

## Empfohlene Spezialisten

Passend zu Stack/Domäne dieses Projekts (Claude-Code-Agents/Skills):

`/deutsche-formulierung`, `@git-workflow`, `/auto-verify`, `@e2e-browser-tester`, `/modern-gui-builder`, `/ux-completeness-check`.

## Hinweis für Änderungen

Vor dem Ändern eines zentralen Bausteins die Abhängigen prüfen — am schnellsten über den **graphify-MCP** (globaler Graph): „Was hängt an `<datei>`?". Brücken-Knoten stabil halten.

