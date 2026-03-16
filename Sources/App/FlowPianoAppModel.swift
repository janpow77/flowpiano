import AudioEngine
import FlowPianoCore
import Foundation
import MIDIEngine
import Persistence
import Settings
import SwiftUI

@MainActor
final class FlowPianoAppModel: ObservableObject {
    @Published private(set) var snapshot: FlowPianoRuntimeSnapshot

    private let coordinator: FlowPianoSessionCoordinator
    private let platformBridge: FlowPianoPlatformBridge?
    let usesLiveSystemServices: Bool

    convenience init() {
        self.init(settingsStore: Self.makeDefaultSettingsStore(), useLiveSystemServices: true)
    }

    init(settingsStore: any SettingsStore, useLiveSystemServices: Bool) {
        coordinator = FlowPianoSessionCoordinator(settingsStore: settingsStore)
        self.usesLiveSystemServices = useLiveSystemServices

        if useLiveSystemServices {
            let bridge = FlowPianoPlatformBridge(coordinator: coordinator)
            platformBridge = bridge
            bridge.start()
        } else {
            platformBridge = nil
            coordinator.installPreviewHardwareProfile()
            try? coordinator.startSession()
        }

        snapshot = coordinator.snapshot
        platformBridge?.onSnapshotChange = { [weak self] in
            self?.refresh()
        }
    }

    func simulatePhrase() {
        let sourceDeviceID = snapshot.midi.connectedDeviceID
        let notes = [60, 64, 67]

        for note in notes {
            try? coordinator.receiveMIDIEvent(MIDIEvent(note: note, velocity: 96, isNoteOn: true, sourceDeviceID: sourceDeviceID))
        }

        for note in notes.reversed() {
            try? coordinator.receiveMIDIEvent(MIDIEvent(note: note, velocity: 0, isNoteOn: false, sourceDeviceID: sourceDeviceID))
        }

        refresh()
    }

    func toggleInternalPiano() {
        coordinator.setInternalPianoEnabled(!snapshot.audio.internalPianoEnabled)
        refresh()
    }

    func swapCameras() {
        coordinator.swapCameraRoles()
        refresh()
    }

    func nudgeOverlay() {
        let frame = snapshot.overlay.frame
        coordinator.moveOverlay(toX: frame.x + 24, y: max(40, frame.y - 12))
        coordinator.resizeOverlay(width: frame.width, height: max(frame.height, 100))
        refresh()
    }

    func cycleRoutingMode() {
        let nextMode: AudioRoutingMode
        switch snapshot.audio.routingMode {
        case .internalOnly:
            nextMode = .layered
        case .layered:
            nextMode = .externalOnly
        case .externalOnly:
            nextMode = .internalOnly
        }

        coordinator.setRoutingMode(nextMode)
        coordinator.setExternalInstrumentConnected(nextMode != .internalOnly)
        coordinator.setSpeechInputLevel(nextMode == .externalOnly ? 0.15 : 0.35)
        refresh()
    }

    func toggleVirtualDevices() {
        coordinator.setVirtualDevicesInstalled(
            cameraInstalled: !snapshot.virtualCamera.isInstalled,
            audioInstalled: !snapshot.virtualAudio.isInstalled
        )
        refresh()
    }

    func saveSettings() {
        try? coordinator.saveSettings()
        refresh()
    }

    func refreshHardware() {
        platformBridge?.refreshHardwareSnapshot()
        refresh()
    }

    func requestPermissions() {
        platformBridge?.requestPermissions()
    }

    func selectMainCamera(id: String?) {
        coordinator.selectCamera(id: id, for: .main)
        refresh()
    }

    func selectPiPCamera(id: String?) {
        coordinator.selectCamera(id: id, for: .pip)
        refresh()
    }

    func selectMIDIInput(id: String?) {
        try? coordinator.connectMIDIInput(id: id)
        refresh()
    }

    func setOverlayVisible(_ isVisible: Bool) {
        coordinator.setOverlayVisible(isVisible)
        refresh()
    }

    func setOverlayLabelsVisible(_ showLabels: Bool) {
        coordinator.setOverlayLabelsVisible(showLabels)
        refresh()
    }

    func setStudioNotationEnabled(_ enabled: Bool) {
        var state = snapshot.settings.studioMonitor
        state.notationEnabled = enabled
        applyStudioMonitorSettings(state)
    }

    func setStudioDiagnosticsEnabled(_ enabled: Bool) {
        var state = snapshot.settings.studioMonitor
        state.diagnosticsEnabled = enabled
        applyStudioMonitorSettings(state)
    }

    func setStudioMetersEnabled(_ enabled: Bool) {
        var state = snapshot.settings.studioMonitor
        state.metersEnabled = enabled
        applyStudioMonitorSettings(state)
    }

    func setStudioEventLogEnabled(_ enabled: Bool) {
        var state = snapshot.settings.studioMonitor
        state.eventLogEnabled = enabled
        applyStudioMonitorSettings(state)
    }

    func setStudioLatencyEnabled(_ enabled: Bool) {
        var state = snapshot.settings.studioMonitor
        state.latencyIndicatorEnabled = enabled
        applyStudioMonitorSettings(state)
    }

    func setOverlayFrame(x: Double? = nil, y: Double? = nil, width: Double? = nil, height: Double? = nil) {
        let current = snapshot.overlay.frame
        coordinator.moveOverlay(toX: x ?? current.x, y: y ?? current.y)
        coordinator.resizeOverlay(width: width ?? current.width, height: height ?? current.height)
        refresh()
    }

    private func refresh() {
        snapshot = coordinator.snapshot
    }

    private func applyStudioMonitorSettings(_ settings: StudioMonitorSettings) {
        coordinator.setStudioMonitorState(
            StudioMonitorState(
                notationEnabled: settings.notationEnabled,
                diagnosticsEnabled: settings.diagnosticsEnabled,
                metersEnabled: settings.metersEnabled,
                eventLogEnabled: settings.eventLogEnabled,
                latencyIndicatorEnabled: settings.latencyIndicatorEnabled
            )
        )
        refresh()
    }

    private static func makeDefaultSettingsStore() -> any SettingsStore {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return InMemorySettingsStore()
        }

        let directoryURL = appSupportURL.appendingPathComponent("FlowPiano", isDirectory: true)
        return FileSettingsStore(directoryURL: directoryURL)
    }
}
