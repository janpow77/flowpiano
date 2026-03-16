import Diagnostics
import FlowPianoCore
import HarmonyTrainer
import LayoutEngine
import SwiftUI

struct ContentView: View {
    @StateObject private var model = FlowPianoAppModel()

    var body: some View {
        NavigationSplitView {
            List {
                Label("Setup", systemImage: "checklist")
                Label("Devices", systemImage: "camera.metering.multispot")
                Label("Audio", systemImage: "pianokeys")
                Label("Outputs", systemImage: "rectangle.on.rectangle")
                Label("Diagnostics", systemImage: "waveform.path.ecg")
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    actionBar
                    setupChecklist
                    configurationRow
                    controlsRow
                    harmonyTrainerSection
                    outputsRow
                    diagnosticsRow
                }
                .padding(24)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FlowPiano")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Production-oriented lesson workstation with hard separation between Public Output and Studio Monitor.")
                        .foregroundStyle(.secondary)
                    Text(model.usesLiveSystemServices ? "Runtime: Live macOS integration" : "Runtime: Preview hardware profile")
                        .font(.subheadline)
                        .foregroundStyle(model.usesLiveSystemServices ? .green : .orange)
                }
                Spacer()
                readinessBadge
            }

            HStack(spacing: 16) {
                metricTile(title: "Latency", value: "\(Int(model.snapshot.estimatedLatencyMilliseconds)) ms")
                metricTile(title: "Public Layers", value: "\(model.snapshot.publicScene.layers.count)")
                metricTile(title: "Diagnostics", value: "\(model.snapshot.diagnostics.issues.count)")
                metricTile(title: "Active Notes", value: "\(model.snapshot.audio.activeNotes.count)")
            }
        }
    }

    private var readinessBadge: some View {
        Text(model.snapshot.diagnostics.isReleaseReady ? "Release Gate Clear" : "Release Gate Blocked")
            .font(.headline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(model.snapshot.diagnostics.isReleaseReady ? Color.green.opacity(0.18) : Color.orange.opacity(0.18))
            .foregroundStyle(model.snapshot.diagnostics.isReleaseReady ? .green : .orange)
            .clipShape(Capsule())
    }

    private var actionBar: some View {
        GroupBox("Session Actions") {
            HStack {
                Button("Refresh Hardware") {
                    model.refreshHardware()
                }
                Button("Request Permissions") {
                    model.requestPermissions()
                }
                Button("Play C Major") {
                    model.simulatePhrase()
                }
                Button(model.snapshot.audio.internalPianoEnabled ? "Disable Internal Piano" : "Enable Internal Piano") {
                    model.toggleInternalPiano()
                }
                Button("Swap Cameras") {
                    model.swapCameras()
                }
                Button("Cycle Routing") {
                    model.cycleRoutingMode()
                }
                Button(model.snapshot.virtualCamera.isInstalled ? "Disable Virtual Devices" : "Enable Virtual Devices") {
                    model.toggleVirtualDevices()
                }
                Button("Save Settings") {
                    model.saveSettings()
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var setupChecklist: some View {
        GroupBox("Setup Flow") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(model.snapshot.setupChecklist) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isComplete ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.step.title)
                                .font(.headline)
                            Text(item.detail)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var configurationRow: some View {
        HStack(alignment: .top, spacing: 20) {
            permissionsAndCameras
            midiAndAudio
        }
    }

    private var permissionsAndCameras: some View {
        GroupBox("Permissions + Cameras") {
            VStack(alignment: .leading, spacing: 12) {
                permissionLine(title: "Camera", granted: model.snapshot.permissions.cameraGranted)
                permissionLine(title: "Microphone", granted: model.snapshot.permissions.microphoneGranted)
                permissionLine(title: "Audio Output", granted: model.snapshot.permissions.audioOutputGranted)

                Divider()

                Picker("Main Camera", selection: mainCameraSelection) {
                    Text("None").tag(Optional<String>.none)
                    ForEach(model.snapshot.video.devices) { device in
                        Text(device.name).tag(Optional(device.id))
                    }
                }

                Picker("PiP Camera", selection: pipCameraSelection) {
                    Text("None").tag(Optional<String>.none)
                    ForEach(model.snapshot.video.devices.filter { $0.id != model.snapshot.video.assignment.mainCameraID }) { device in
                        Text(device.name).tag(Optional(device.id))
                    }
                }

                Text("Mode: \(model.snapshot.video.mode.rawValue)")
                    .font(.headline)
                Text("MultiCam: \(model.snapshot.video.capabilities.supportsMultiCam ? "Supported" : "Fallback only")")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var midiAndAudio: some View {
        GroupBox("MIDI + Audio") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("MIDI Input", selection: midiSelection) {
                    Text("Disconnected").tag(Optional<String>.none)
                    ForEach(model.snapshot.midi.devices) { device in
                        Text(device.name).tag(Optional(device.id))
                    }
                }

                Text("Routing: \(routingTitle)")
                    .font(.headline)
                Text("Piano Bank: \(model.snapshot.audio.runtime.pianoSoundBankName)")
                Text("Bank Source: \(model.snapshot.audio.runtime.pianoSoundBankSource.rawValue)")
                    .foregroundStyle(.secondary)
                Text("Speech Input: \(model.snapshot.audio.runtime.speechInputAvailable ? "Available" : "Unavailable")")
                    .foregroundStyle(.secondary)
                if let runtimeError = model.snapshot.audio.runtime.lastError {
                    Text(runtimeError)
                        .foregroundStyle(.orange)
                }

                Divider()

                meterBar(title: "Piano", value: model.snapshot.audio.meters.pianoLevel)
                meterBar(title: "Speech", value: model.snapshot.audio.meters.speechLevel)
                meterBar(title: "External", value: model.snapshot.audio.meters.externalLevel)
                meterBar(title: "Master", value: model.snapshot.audio.meters.masterLevel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var controlsRow: some View {
        HStack(alignment: .top, spacing: 20) {
            overlayControls
            studioMonitorControls
        }
    }

    private var overlayControls: some View {
        GroupBox("Overlay Layout") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Overlay Visible", isOn: Binding(
                    get: { model.snapshot.overlay.isVisible },
                    set: { model.setOverlayVisible($0) }
                ))

                Toggle("Key Labels", isOn: Binding(
                    get: { model.snapshot.settings.overlay.showLabels },
                    set: { model.setOverlayLabelsVisible($0) }
                ))

                overlaySlider(
                    title: "X",
                    value: model.snapshot.overlay.frame.x,
                    range: 0...1600
                ) { model.setOverlayFrame(x: $0) }

                overlaySlider(
                    title: "Y",
                    value: model.snapshot.overlay.frame.y,
                    range: 0...1000
                ) { model.setOverlayFrame(y: $0) }

                overlaySlider(
                    title: "Width",
                    value: model.snapshot.overlay.frame.width,
                    range: 300...1900
                ) { model.setOverlayFrame(width: $0) }

                overlaySlider(
                    title: "Height",
                    value: model.snapshot.overlay.frame.height,
                    range: 80...220
                ) { model.setOverlayFrame(height: $0) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var studioMonitorControls: some View {
        GroupBox("Studio Monitor") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Notation", isOn: Binding(
                    get: { model.snapshot.settings.studioMonitor.notationEnabled },
                    set: { model.setStudioNotationEnabled($0) }
                ))
                Toggle("Diagnostics", isOn: Binding(
                    get: { model.snapshot.settings.studioMonitor.diagnosticsEnabled },
                    set: { model.setStudioDiagnosticsEnabled($0) }
                ))
                Toggle("Meters", isOn: Binding(
                    get: { model.snapshot.settings.studioMonitor.metersEnabled },
                    set: { model.setStudioMetersEnabled($0) }
                ))
                Toggle("MIDI Log", isOn: Binding(
                    get: { model.snapshot.settings.studioMonitor.eventLogEnabled },
                    set: { model.setStudioEventLogEnabled($0) }
                ))
                Toggle("Latency", isOn: Binding(
                    get: { model.snapshot.settings.studioMonitor.latencyIndicatorEnabled },
                    set: { model.setStudioLatencyEnabled($0) }
                ))
                Toggle("Harmony Trainer", isOn: Binding(
                    get: { model.snapshot.harmonyTrainer.isEnabled },
                    set: { model.setHarmonyTrainerEnabled($0) }
                ))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var harmonyTrainerSection: some View {
        GroupBox("Harmony Trainer") {
            if model.snapshot.harmonyTrainer.isEnabled {
                HarmonyTrainerView(
                    state: model.snapshot.harmonyTrainer,
                    onSetKey: { model.setHarmonyTrainerKey($0) },
                    onSetScaleType: { model.setHarmonyTrainerScaleType($0) },
                    onSetMode: { model.setHarmonyExerciseMode($0) },
                    onSelectProgression: { model.startHarmonyProgression($0) },
                    onAdvance: { model.advanceHarmonyExercise() },
                    onReset: { model.resetHarmonyExercise() }
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Harmony Trainer ist deaktiviert")
                        .foregroundStyle(.secondary)
                    Text("Aktiviere ihn im Studio Monitor Panel, um Akkorde, Stufen und Progressionen zu trainieren.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Aktivieren") {
                        model.setHarmonyTrainerEnabled(true)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
    }

    private var outputsRow: some View {
        HStack(alignment: .top, spacing: 20) {
            GroupBox("Public Output") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.snapshot.publicScene.layers) { layer in
                        outputLayerLine(title: label(for: layer.kind), frame: layer.frame)
                    }
                    if model.snapshot.publicScene.layers.isEmpty {
                        Text("No public layers available.")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Studio Monitor Output") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.snapshot.studioMonitor.visibleLayers, id: \.self) { layer in
                        Text(label(for: layer))
                    }
                    if let latency = model.snapshot.studioMonitor.latencyMilliseconds {
                        Text("Latency indicator: \(Int(latency)) ms")
                            .foregroundStyle(.secondary)
                    }
                    if !model.snapshot.overlay.activeKeys.isEmpty {
                        Text("Overlay notes: \(model.snapshot.overlay.activeKeys.map { String($0.note) }.joined(separator: ", "))")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var diagnosticsRow: some View {
        HStack(alignment: .top, spacing: 20) {
            GroupBox("Notation") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(model.snapshot.notation.recentSymbols.prefix(8)) { symbol in
                        Text("\(symbol.noteName)\(symbol.octave) · velocity \(symbol.velocity)")
                    }

                    if model.snapshot.notation.recentSymbols.isEmpty {
                        Text("No notation events yet.")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Diagnostics") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.snapshot.diagnostics.issues) { issue in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.message)
                                .font(.headline)
                                .foregroundStyle(color(for: issue.severity))
                            Text(issue.recoverySuggestion)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if model.snapshot.diagnostics.issues.isEmpty {
                        Text("No active diagnostics.")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var mainCameraSelection: Binding<String?> {
        Binding(
            get: { model.snapshot.video.assignment.mainCameraID },
            set: { model.selectMainCamera(id: $0) }
        )
    }

    private var pipCameraSelection: Binding<String?> {
        Binding(
            get: { model.snapshot.video.assignment.pipCameraID },
            set: { model.selectPiPCamera(id: $0) }
        )
    }

    private var midiSelection: Binding<String?> {
        Binding(
            get: { model.snapshot.midi.connectedDeviceID },
            set: { model.selectMIDIInput(id: $0) }
        )
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func permissionLine(title: String, granted: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(granted ? "Granted" : "Missing")
                .foregroundStyle(granted ? .green : .orange)
        }
    }

    private func overlaySlider(title: String, value: Double, range: ClosedRange<Double>, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value))")
                    .monospacedDigit()
            }
            Slider(value: Binding(get: { value }, set: onChange), in: range)
        }
    }

    private func outputLayerLine(title: String, frame: LayerFrame) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text("x \(Int(frame.x)) · y \(Int(frame.y)) · \(Int(frame.width)) × \(Int(frame.height))")
                .foregroundStyle(.secondary)
        }
    }

    private func meterBar(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value * 100))%")
                    .monospacedDigit()
            }
            ProgressView(value: value)
        }
    }

    private var routingTitle: String {
        switch model.snapshot.audio.routingMode {
        case .internalOnly:
            return "Internal Only"
        case .layered:
            return "Layered"
        case .externalOnly:
            return "External Only"
        }
    }

    private func label(for layer: LayerKind) -> String {
        switch layer {
        case .mainCamera:
            return "Main Camera"
        case .pipCamera:
            return "PiP Camera"
        case .midiOverlay:
            return "MIDI Overlay"
        case .musicStaff:
            return "Music Staff"
        case .audioMeters:
            return "Audio Meters"
        case .midiEventLog:
            return "MIDI Event Log"
        case .latencyIndicator:
            return "Latency Indicator"
        case .diagnostics:
            return "Diagnostics"
        case .harmonyTrainer:
            return "Harmony Trainer"
        }
    }

    private func color(for severity: DiagnosticSeverity) -> Color {
        switch severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}
