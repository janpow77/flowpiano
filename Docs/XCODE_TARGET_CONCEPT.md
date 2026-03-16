# XCODE_TARGET_CONCEPT.md — FlowPiano
Version 1.0

## Ziel

Dieses Dokument definiert ein sauberes Xcode-Target-Konzept für **FlowPiano** als produktionsreife macOS-Anwendung mit:

- Host-App
- Virtual Camera Extension
- Virtual Audio Driver / Audio Device-Komponente
- Unit-, Integration- und UI-Tests
- klarer Trennung von Shared Code und target-spezifischem Code

---

## 1 Zielstruktur in Xcode

Empfohlene Targets:

1. **FlowPianoApp**
   - Typ: macOS App
   - Aufgabe:
     - Hauptoberfläche
     - Setup Wizard
     - Studio Monitor
     - Geräteauswahl
     - Audio-/MIDI-/Layout-Konfiguration
     - Steuerung der Extensions / Runtime-Status

2. **FlowPianoCore**
   - Typ: Framework oder Shared Module Group
   - Aufgabe:
     - gemeinsame Domain-Modelle
     - Layout-Modelle
     - Settings
     - Diagnostics
     - MIDI-Event-Modelle
     - Notation-Modelle
   - Wird verwendet von:
     - FlowPianoApp
     - VirtualCameraExtension
     - VirtualAudioDriver (soweit möglich)

3. **FlowPianoVideoEngine**
   - Typ: Framework / Shared Module
   - Aufgabe:
     - Kameraerkennung
     - Capture-Steuerung
     - MultiCam-Checks
     - Frame-Komposition
     - Render-Target-Trennung

4. **FlowPianoAudioEngine**
   - Typ: Framework / Shared Module
   - Aufgabe:
     - interner Piano-Sampler
     - Mikrofon-Mixing
     - Routing-Status
     - Metering
     - Audio-Sicherheitslogik

5. **FlowPianoMIDIEngine**
   - Typ: Framework / Shared Module
   - Aufgabe:
     - MIDI-Geräteerkennung
     - NOTE ON / NOTE OFF
     - Velocity
     - Reconnect
     - Kalibrierung

6. **FlowPianoVirtualCameraExtension**
   - Typ: Camera Extension / System Extension
   - Aufgabe:
     - Public Output als virtuelle Kamera veröffentlichen

7. **FlowPianoVirtualAudioDriver**
   - Typ: Audio Driver / Driver-Komponente
   - Aufgabe:
     - gemischtes Audiosignal als virtuelles Mikrofon bereitstellen

8. **FlowPianoUnitTests**
   - Typ: Unit Test Bundle

9. **FlowPianoIntegrationTests**
   - Typ: Test Bundle

10. **FlowPianoUITests**
    - Typ: UI Test Bundle

---

## 2 Empfohlene Zielabhängigkeiten

### FlowPianoApp
abhängig von:
- FlowPianoCore
- FlowPianoVideoEngine
- FlowPianoAudioEngine
- FlowPianoMIDIEngine

### FlowPianoVirtualCameraExtension
abhängig von:
- FlowPianoCore
- FlowPianoVideoEngine

### FlowPianoVirtualAudioDriver
abhängig von:
- FlowPianoCore
- FlowPianoAudioEngine

### Tests
abhängig von:
- den jeweiligen Kernmodulen
- optional Host-App für UI-Tests

---

## 3 Trennung von Shared Code und Extension-Code

Wichtige Regel:

Der Shared Code darf **keine App-UI-Abhängigkeiten** enthalten.

### In Shared/Core erlaubt
- Foundation
- Codable Modelle
- OSLog
- Business Rules
- Layout Visibility Logic
- MIDI Event Models
- Settings Migration Logic

### In Shared/Core nicht erlaubt
- direkte SwiftUI-Views für App-spezifische Fenster
- App-Lifecycle-Code
- target-spezifische Extension-Installation
- harte UI-Referenzen

So bleibt der Core-Code in App und Extensions wiederverwendbar.

---

## 4 Bundle- und Identifier-Konzept

Empfohlen:

- App:
  - `com.example.FlowPiano`

- Virtual Camera Extension:
  - `com.example.FlowPiano.VirtualCameraExtension`

- Virtual Audio Driver:
  - `com.example.FlowPiano.VirtualAudioDriver`

- Unit Tests:
  - `com.example.FlowPiano.UnitTests`

- UI Tests:
  - `com.example.FlowPiano.UITests`

Diese Werte sind Platzhalter und vor echtem Signing anzupassen.

---

## 5 Build Configurations

Empfohlene Build-Konfigurationen:

- `Debug`
- `Release`
- optional `SignedRelease`

### Debug
- zusätzliche Logs
- Testdaten erlaubt
- lokale Entwicklung

### Release
- produktionsnahe Flags
- minimale Debug-Ausgaben
- Release-Optimierung

### SignedRelease
- für Signing / Notarisierung vorbereitet
- identisch zu Release, aber mit produktionsnaher Distribution-Konfiguration

---

## 6 Entitlements-Konzept

### App
Mögliche Anforderungen:
- Kamera
- Mikrofon
- MIDI / Audio Zugriff
- System Extension Install Flow

### Virtual Camera Extension
- spezifische Camera-/System-Extension-Entitlements

### Virtual Audio Driver
- Driver-/Audio-spezifische Entitlements

Wichtig:
Die konkreten Entitlements müssen anhand des finalen Apple-Developer-Setups gepflegt werden.

---

## 7 Scheme-Konzept

Empfohlene Schemes:

- `FlowPiano-App`
- `FlowPiano-UnitTests`
- `FlowPiano-IntegrationTests`
- `FlowPiano-UITests`
- optional `FlowPiano-ReleaseValidation`

---

## 8 Datei- und Gruppierungsstruktur in Xcode

Empfohlene Xcode-Gruppen:

- App
- Core
- VideoEngine
- AudioEngine
- MIDIEngine
- NotationEngine
- OverlayEngine
- LayoutEngine
- StudioMonitor
- VirtualCameraExtension
- VirtualAudioDriver
- Resources
- Tests
- Docs
- Config

---

## 9 Kritische technische Trennung

### Public Output
Wird in die Virtual Camera Extension eingespeist.

Darf nur enthalten:
- Face Cam
- Keyboard Cam
- MIDI Overlay

### Studio Monitor
Bleibt ausschließlich lokal in der App.

Darf zusätzlich enthalten:
- Notation
- Meter
- MIDI Log
- Latency
- Diagnostics

Die Sichtbarkeitslogik darf nicht nur UI-gesteuert sein.
Sie muss im gemeinsamen Render-/Layout-Modell technisch erzwungen werden.

---

## 10 Testtargets und Pflichtabdeckung

### Unit Tests
Pflicht:
- Layer Visibility Matrix
- Settings Persistenz
- MIDI Mapping
- Key Signature Mapping
- Layout Restore
- Default Target Separation

### Integration Tests
Pflicht:
- Startup Flow
- Camera Slot Assignment
- Internal Piano Mode
- Public vs Studio Composition
- Reconnect Handling

### UI Tests
Pflicht:
- Setup Wizard
- Layout Editor
- Studio Monitor Controls
- Audio Routing Screen

---

## 11 Reihenfolge für die Anlage in Xcode

1. macOS App Target anlegen
2. Shared Framework / lokale Swift Packages definieren
3. Unit Test Target anlegen
4. UI Test Target anlegen
5. Video-/Audio-/MIDI-Module anbinden
6. Virtual Camera Extension Target ergänzen
7. Virtual Audio Driver / Driver-Komponente ergänzen
8. Signing / Entitlements vorbereiten
9. Schemes bereinigen
10. Release Build-Pfade dokumentieren

---

## 12 Definition of Done für die Projektstruktur

Die Xcode-Struktur ist fertig, wenn:

- alle Kernmodule sauber getrennt sind
- die App unabhängig startbar ist
- Tests laufen
- Shared Code nicht mit App-UI vermischt ist
- Virtual Camera Pfad isoliert vorbereitet ist
- Virtual Audio Pfad isoliert vorbereitet ist
- Signing/Entitlement-Platzhalter dokumentiert sind
