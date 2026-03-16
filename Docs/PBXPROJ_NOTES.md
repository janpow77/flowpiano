# PBXPROJ_NOTES.md — FlowPiano
Version 1.0

## Zweck

Dieses Dokument beschreibt, wie Codex oder ein Entwickler das echte `.xcodeproj` nachziehen soll.

Das aktuell gelieferte Projektgerüst ist absichtlich minimal.
Für eine reale produktionsreife Struktur sollte das `.pbxproj` folgende Elemente enthalten:

- App Target `FlowPianoApp`
- Framework / Shared Module Targets
- Test Targets
- separate Build Phases
- Resources Build Phase
- Signing Settings
- entitlements-Dateien
- target-spezifische Info.plist-Dateien

---

## Mindestdateien pro Target

### FlowPianoApp
- `Config/App/Info.plist`
- `Config/App/FlowPianoApp.entitlements`

### FlowPianoVirtualCameraExtension
- `Config/VirtualCamera/Info.plist`
- `Config/VirtualCamera/FlowPianoVirtualCameraExtension.entitlements`

### FlowPianoVirtualAudioDriver
- `Config/VirtualAudio/Info.plist`
- `Config/VirtualAudio/FlowPianoVirtualAudioDriver.entitlements`

### Tests
- eigene Test-Bundles mit jeweils passendem Bundle Identifier

---

## Empfehlung

Codex soll das `.xcodeproj` nicht blind überschreiben, sondern:

1. bestehende Repo-Struktur lesen
2. Targets konsistent auf Basis der Docs anlegen
3. Build Settings je Target dokumentiert setzen
4. Signing/Notarisierungsstellen als klar dokumentierte Platzhalter hinterlegen
