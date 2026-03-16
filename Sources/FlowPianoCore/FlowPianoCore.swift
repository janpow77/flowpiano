import AudioEngine
import Diagnostics
import Foundation
import LayoutEngine
import MIDIEngine
import NotationEngine
import OverlayEngine
import Persistence
import Settings
import StudioMonitor
import VideoEngine
import VirtualAudioDriver
import VirtualCameraExtension

public enum SetupStep: String, Codable, CaseIterable, Identifiable {
    case permissions
    case mainCamera
    case pipCamera
    case midiKeyboard
    case internalPiano
    case overlayPlacement
    case studioNotation
    case virtualDevices

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .permissions:
            return "Grant Permissions"
        case .mainCamera:
            return "Choose Main Camera"
        case .pipCamera:
            return "Choose PiP Camera"
        case .midiKeyboard:
            return "Connect MIDI Keyboard"
        case .internalPiano:
            return "Test Internal Piano"
        case .overlayPlacement:
            return "Position MIDI Overlay"
        case .studioNotation:
            return "Verify Studio Notation"
        case .virtualDevices:
            return "Validate Virtual Devices"
        }
    }
}

public struct SetupChecklistItem: Equatable, Codable, Identifiable {
    public let step: SetupStep
    public let isComplete: Bool
    public let detail: String

    public var id: String { step.rawValue }

    public init(step: SetupStep, isComplete: Bool, detail: String) {
        self.step = step
        self.isComplete = isComplete
        self.detail = detail
    }
}

public struct FlowPianoRuntimeSnapshot: Equatable, Codable {
    public var settings: AppSettings
    public var permissions: PermissionState
    public var video: VideoSessionState
    public var midi: MIDIConnectionStatus
    public var audio: AudioEngineState
    public var notation: NotationState
    public var overlay: MIDIOverlayState
    public var diagnostics: DiagnosticsReport
    public var publicScene: RenderScene
    public var studioMonitor: StudioMonitorSnapshot
    public var virtualCamera: VirtualCameraStatus
    public var virtualAudio: VirtualAudioDriverStatus
    public var setupChecklist: [SetupChecklistItem]
    public var publicSceneViolations: [LayerKind]
    public var estimatedLatencyMilliseconds: Double

    public init(
        settings: AppSettings,
        permissions: PermissionState,
        video: VideoSessionState,
        midi: MIDIConnectionStatus,
        audio: AudioEngineState,
        notation: NotationState,
        overlay: MIDIOverlayState,
        diagnostics: DiagnosticsReport,
        publicScene: RenderScene,
        studioMonitor: StudioMonitorSnapshot,
        virtualCamera: VirtualCameraStatus,
        virtualAudio: VirtualAudioDriverStatus,
        setupChecklist: [SetupChecklistItem],
        publicSceneViolations: [LayerKind],
        estimatedLatencyMilliseconds: Double
    ) {
        self.settings = settings
        self.permissions = permissions
        self.video = video
        self.midi = midi
        self.audio = audio
        self.notation = notation
        self.overlay = overlay
        self.diagnostics = diagnostics
        self.publicScene = publicScene
        self.studioMonitor = studioMonitor
        self.virtualCamera = virtualCamera
        self.virtualAudio = virtualAudio
        self.setupChecklist = setupChecklist
        self.publicSceneViolations = publicSceneViolations
        self.estimatedLatencyMilliseconds = estimatedLatencyMilliseconds
    }
}

public final class FlowPianoSessionCoordinator {
    private let settingsStore: any SettingsStore
    private let settingsKey = "flowpiano-settings"

    private let videoEngine: VideoEngine
    private let midiEngine: MIDIEngine
    private let audioEngine: AudioEngine
    private let notationEngine: NotationEngine
    private let overlayEngine: OverlayEngine
    private let virtualCamera: VirtualCameraExtension
    private let virtualAudio: VirtualAudioDriver

    private var settings: AppSettings
    private var permissions = PermissionState()
    private var studioMonitorState = StudioMonitorState()

    public private(set) var snapshot: FlowPianoRuntimeSnapshot

    public init(
        settingsStore: any SettingsStore = InMemorySettingsStore(),
        videoEngine: VideoEngine = VideoEngine(),
        midiEngine: MIDIEngine = MIDIEngine(),
        audioEngine: AudioEngine = AudioEngine(),
        notationEngine: NotationEngine = NotationEngine(),
        overlayEngine: OverlayEngine = OverlayEngine(),
        virtualCamera: VirtualCameraExtension = VirtualCameraExtension(),
        virtualAudio: VirtualAudioDriver = VirtualAudioDriver()
    ) {
        self.settingsStore = settingsStore
        self.videoEngine = videoEngine
        self.midiEngine = midiEngine
        self.audioEngine = audioEngine
        self.notationEngine = notationEngine
        self.overlayEngine = overlayEngine
        self.virtualCamera = virtualCamera
        self.virtualAudio = virtualAudio

        self.settings = (try? settingsStore.load(AppSettings.self, forKey: settingsKey)) ?? AppSettings()
        applySettingsToEngines()
        self.snapshot = FlowPianoRuntimeSnapshot(
            settings: self.settings,
            permissions: permissions,
            video: videoEngine.state,
            midi: midiEngine.state,
            audio: audioEngine.state,
            notation: notationEngine.state,
            overlay: overlayEngine.state,
            diagnostics: DiagnosticsReport(),
            publicScene: LayoutEngine.buildScene(in: LayoutEngine.sanitizedForPublicOutput(self.settings.layout), for: .publicOutput),
            studioMonitor: StudioMonitorSnapshot(visibleLayers: [], notation: nil, audioMeters: nil, midiLog: [], diagnostics: nil, latencyMilliseconds: nil),
            virtualCamera: virtualCamera.status,
            virtualAudio: virtualAudio.status,
            setupChecklist: [],
            publicSceneViolations: [],
            estimatedLatencyMilliseconds: 0
        )
        refreshSnapshot()
    }

    public func installPreviewHardwareProfile() {
        updateAvailableCameras(
            [
                CameraDevice(id: "cam-face", name: "Face Camera", position: .front),
                CameraDevice(id: "cam-keys", name: "Keyboard Camera", position: .external)
            ],
            capabilities: VideoCapabilities(supportsMultiCam: true, maxActiveCameras: 2)
        )
        updateAvailableMIDIInputs([MIDIDevice(id: "midi-main", name: "88-Key Controller")])
        try? connectMIDIInput(id: "midi-main")
        setPermissions(cameraGranted: true, microphoneGranted: true, audioOutputGranted: true)
        setVirtualDevicesInstalled(cameraInstalled: true, audioInstalled: true)
    }

    public func setPermissions(cameraGranted: Bool, microphoneGranted: Bool, audioOutputGranted: Bool) {
        permissions = PermissionState(
            cameraGranted: cameraGranted,
            microphoneGranted: microphoneGranted,
            audioOutputGranted: audioOutputGranted
        )
        refreshSnapshot()
    }

    public func updateAvailableCameras(_ devices: [CameraDevice], capabilities: VideoCapabilities) {
        videoEngine.updateDevices(devices, capabilities: capabilities)
        if let mainCameraID = settings.video.preferredMainCameraID {
            videoEngine.selectCamera(id: mainCameraID, for: .main)
        }
        if let pipCameraID = settings.video.preferredPiPCameraID {
            videoEngine.selectCamera(id: pipCameraID, for: .pip)
        }
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func selectCamera(id: String?, for role: CameraRole) {
        videoEngine.selectCamera(id: id, for: role)
        switch role {
        case .main:
            settings.video.preferredMainCameraID = videoEngine.state.assignment.mainCameraID
        case .pip:
            settings.video.preferredPiPCameraID = videoEngine.state.assignment.pipCameraID
        }
        persistSettingsIfPossible()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func swapCameraRoles() {
        videoEngine.swapCameraRoles()
        settings.video.preferredMainCameraID = videoEngine.state.assignment.mainCameraID
        settings.video.preferredPiPCameraID = videoEngine.state.assignment.pipCameraID
        settings.layout = LayoutEngine.swapCameraFrames(in: settings.layout)
        persistSettingsIfPossible()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func updateAvailableMIDIInputs(_ devices: [MIDIDevice]) {
        midiEngine.updateAvailableDevices(devices)
        if settings.midi.autoReconnect, let preferredInputDeviceID = settings.midi.preferredInputDeviceID {
            try? midiEngine.connect(to: preferredInputDeviceID)
        }
        refreshSnapshot()
    }

    public func connectMIDIInput(id: String?) throws {
        try midiEngine.connect(to: id)
        settings.midi.preferredInputDeviceID = midiEngine.state.connectedDeviceID
        persistSettingsIfPossible()
        refreshSnapshot()
    }

    public func receiveMIDIEvent(_ event: MIDIEvent) throws {
        try midiEngine.receive(event)
        audioEngine.process(event)
        notationEngine.consume(event)
        overlayEngine.update(from: midiEngine.state)
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func setInternalPianoEnabled(_ enabled: Bool) {
        settings.audio.useInternalPiano = enabled
        audioEngine.setInternalPianoEnabled(enabled)
        persistSettingsIfPossible()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func setRoutingMode(_ routingMode: AudioRoutingMode) {
        settings.audio.routingPreference = audioRoutingPreference(for: routingMode)
        audioEngine.setRoutingMode(routingMode)
        persistSettingsIfPossible()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func setSpeechInputLevel(_ level: Double) {
        audioEngine.setSpeechInputLevel(level)
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func setExternalInstrumentConnected(_ connected: Bool) {
        audioEngine.setExternalInstrumentConnected(connected)
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func moveOverlay(toX x: Double, y: Double) {
        settings.layout = LayoutEngine.moveLayer(.midiOverlay, toX: x, y: y, in: settings.layout)
        syncOverlayFrameFromLayout()
        persistSettingsIfPossible()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func resizeOverlay(width: Double, height: Double) {
        settings.layout = LayoutEngine.resizeLayer(.midiOverlay, width: width, height: height, in: settings.layout)
        syncOverlayFrameFromLayout()
        persistSettingsIfPossible()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func setOverlayVisible(_ isVisible: Bool) {
        settings.overlay.isVisible = isVisible
        overlayEngine.setVisible(isVisible)
        persistSettingsIfPossible()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func setOverlayLabelsVisible(_ showLabels: Bool) {
        settings.overlay.showLabels = showLabels
        overlayEngine.setShowLabels(showLabels)
        persistSettingsIfPossible()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func setStudioMonitorState(_ state: StudioMonitorState) {
        studioMonitorState = state
        settings.studioMonitor = StudioMonitorSettings(
            notationEnabled: state.notationEnabled,
            diagnosticsEnabled: state.diagnosticsEnabled,
            metersEnabled: state.metersEnabled,
            eventLogEnabled: state.eventLogEnabled,
            latencyIndicatorEnabled: state.latencyIndicatorEnabled
        )
        persistSettingsIfPossible()
        refreshSnapshot()
    }

    public func setVirtualDevicesInstalled(cameraInstalled: Bool, audioInstalled: Bool) {
        if cameraInstalled {
            virtualCamera.install()
        } else {
            virtualCamera.uninstall()
        }

        if audioInstalled {
            virtualAudio.install()
        } else {
            virtualAudio.uninstall()
        }

        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func startSession() throws {
        try videoEngine.start()
        try audioEngine.start()
        publishOutputsIfPossible()
        refreshSnapshot()
    }

    public func stopSession() {
        videoEngine.stop()
        audioEngine.stop()
        virtualCamera.stopPublishing()
        virtualAudio.stopPublishing()
        refreshSnapshot()
    }

    public func saveSettings() throws {
        try settingsStore.save(settings, forKey: settingsKey)
    }

    private func applySettingsToEngines() {
        audioEngine.setInternalPianoEnabled(settings.audio.useInternalPiano)
        audioEngine.setRoutingMode(audioRoutingMode(for: settings.audio.routingPreference))
        audioEngine.setMixProfile(
            AudioMixProfile(
                pianoGain: settings.audio.pianoGain,
                speechGain: settings.audio.speechGain,
                externalInstrumentGain: settings.audio.externalInstrumentGain,
                masterGain: 1
            )
        )
        overlayEngine.setVisible(settings.overlay.isVisible)
        overlayEngine.setShowLabels(settings.overlay.showLabels)
        studioMonitorState = StudioMonitorState(
            notationEnabled: settings.studioMonitor.notationEnabled,
            diagnosticsEnabled: settings.studioMonitor.diagnosticsEnabled,
            metersEnabled: settings.studioMonitor.metersEnabled,
            eventLogEnabled: settings.studioMonitor.eventLogEnabled,
            latencyIndicatorEnabled: settings.studioMonitor.latencyIndicatorEnabled
        )
        syncOverlayFrameFromLayout()
    }

    private func syncOverlayFrameFromLayout() {
        if let overlayLayer = settings.layout.layers.first(where: { $0.kind == .midiOverlay }) {
            overlayEngine.setFrame(overlayLayer.frame)
        }
    }

    private func refreshSnapshot() {
        syncOverlayFrameFromLayout()
        overlayEngine.update(from: midiEngine.state)

        let resolvedLayout = resolvedLayoutConfiguration()
        let publicSceneViolations = LayoutEngine.validatePublicOutput(in: resolvedLayout)
        let publicScene = LayoutEngine.buildScene(in: LayoutEngine.sanitizedForPublicOutput(resolvedLayout), for: .publicOutput)
        let estimatedLatencyMilliseconds = calculateLatencyEstimate()
        let checklistWithoutDiagnostics = buildSetupChecklist()
        let setupComplete = checklistWithoutDiagnostics.allSatisfy(\.isComplete)
        let diagnostics = Diagnostics.buildReport(
            permissions: permissions,
            video: videoEngine.state,
            midi: midiEngine.state,
            audio: audioEngine.state,
            publicSceneViolations: publicSceneViolations,
            virtualCamera: virtualCamera.status,
            virtualAudio: virtualAudio.status,
            setupComplete: setupComplete
        )
        let studioMonitor = StudioMonitor.buildSnapshot(
            layout: resolvedLayout,
            state: studioMonitorState,
            notation: notationEngine.state,
            audio: audioEngine.state,
            midi: midiEngine.state,
            diagnostics: diagnostics,
            latencyMilliseconds: estimatedLatencyMilliseconds
        )

        snapshot = FlowPianoRuntimeSnapshot(
            settings: settings,
            permissions: permissions,
            video: videoEngine.state,
            midi: midiEngine.state,
            audio: audioEngine.state,
            notation: notationEngine.state,
            overlay: overlayEngine.state,
            diagnostics: diagnostics,
            publicScene: publicScene,
            studioMonitor: studioMonitor,
            virtualCamera: virtualCamera.status,
            virtualAudio: virtualAudio.status,
            setupChecklist: checklistWithoutDiagnostics,
            publicSceneViolations: publicSceneViolations,
            estimatedLatencyMilliseconds: estimatedLatencyMilliseconds
        )
    }

    private func buildSetupChecklist() -> [SetupChecklistItem] {
        let resolvedLayout = resolvedLayoutConfiguration()
        let overlayFrame = settings.layout.layers.first(where: { $0.kind == .midiOverlay })?.frame
        let hasSecondCameraOption = videoEngine.state.devices.filter(\.isAvailable).count > 1 && videoEngine.state.capabilities.supportsMultiCam
        let notationVisibleOnlyInStudio = LayoutEngine.visibleLayers(in: resolvedLayout, for: .publicOutput).contains(where: { $0.kind == .musicStaff }) == false
            && LayoutEngine.visibleLayers(in: resolvedLayout, for: .studioMonitor).contains(where: { $0.kind == .musicStaff })
        let virtualDevicesComplete = (!settings.virtualDevices.autoPublishCamera || virtualCamera.status.isInstalled)
            && (!settings.virtualDevices.autoPublishMicrophone || virtualAudio.status.isInstalled)

        return [
            SetupChecklistItem(
                step: .permissions,
                isComplete: permissions.cameraGranted && permissions.microphoneGranted,
                detail: "Camera and microphone permissions must be granted."
            ),
            SetupChecklistItem(
                step: .mainCamera,
                isComplete: videoEngine.state.assignment.mainCameraID != nil,
                detail: "A main camera must be selected for the public output."
            ),
            SetupChecklistItem(
                step: .pipCamera,
                isComplete: !hasSecondCameraOption || videoEngine.state.assignment.pipCameraID != nil,
                detail: "Choose a second camera when hardware supports PiP."
            ),
            SetupChecklistItem(
                step: .midiKeyboard,
                isComplete: midiEngine.state.isConnected,
                detail: "A MIDI keyboard should be connected and discoverable."
            ),
            SetupChecklistItem(
                step: .internalPiano,
                isComplete: audioEngine.state.internalPianoEnabled && audioEngine.state.isRunning,
                detail: "Internal piano mode should be enabled and audio running."
            ),
            SetupChecklistItem(
                step: .overlayPlacement,
                isComplete: settings.overlay.isVisible && (overlayFrame.map { $0.width >= 600 && $0.height >= 80 } ?? false),
                detail: "The MIDI overlay must be visible and large enough to teach from."
            ),
            SetupChecklistItem(
                step: .studioNotation,
                isComplete: studioMonitorState.notationEnabled && notationVisibleOnlyInStudio,
                detail: "Notation must remain local-only on the Studio Monitor."
            ),
            SetupChecklistItem(
                step: .virtualDevices,
                isComplete: virtualDevicesComplete,
                detail: "Install the virtual camera and microphone when they are required."
            )
        ]
    }

    private func calculateLatencyEstimate() -> Double {
        let cameraCost = videoEngine.state.mode == .dualCamera ? 18.0 : 12.0
        let midiCost = midiEngine.state.isConnected ? 4.0 : 0.0
        let audioCost = audioEngine.state.internalPianoEnabled ? 6.0 : 3.0
        return cameraCost + midiCost + audioCost
    }

    private func publishOutputsIfPossible() {
        let publicScene = LayoutEngine.buildScene(
            in: LayoutEngine.sanitizedForPublicOutput(resolvedLayoutConfiguration()),
            for: .publicOutput
        )

        if settings.virtualDevices.autoPublishCamera {
            try? virtualCamera.publish(scene: publicScene)
        }

        if settings.virtualDevices.autoPublishMicrophone {
            try? virtualAudio.publish(state: audioEngine.state)
        }
    }

    private func audioRoutingMode(for preference: AudioRoutingPreference) -> AudioRoutingMode {
        switch preference {
        case .internalOnly:
            return .internalOnly
        case .layered:
            return .layered
        case .externalOnly:
            return .externalOnly
        }
    }

    private func audioRoutingPreference(for mode: AudioRoutingMode) -> AudioRoutingPreference {
        switch mode {
        case .internalOnly:
            return .internalOnly
        case .layered:
            return .layered
        case .externalOnly:
            return .externalOnly
        }
    }

    private func resolvedLayoutConfiguration() -> LayoutConfiguration {
        LayoutConfiguration(
            layers: settings.layout.layers.map { layer in
                var updated = layer

                switch layer.kind {
                case .mainCamera, .pipCamera:
                    break
                case .midiOverlay:
                    updated.visibility.publicVisible = settings.overlay.isVisible
                    updated.visibility.studioVisible = settings.overlay.isVisible
                case .musicStaff:
                    updated.visibility.studioVisible = studioMonitorState.notationEnabled
                case .audioMeters:
                    updated.visibility.studioVisible = studioMonitorState.metersEnabled
                case .midiEventLog:
                    updated.visibility.studioVisible = studioMonitorState.eventLogEnabled
                case .latencyIndicator:
                    updated.visibility.studioVisible = studioMonitorState.latencyIndicatorEnabled
                case .diagnostics:
                    updated.visibility.studioVisible = studioMonitorState.diagnosticsEnabled
                }

                return updated
            }
        )
    }

    private func persistSettingsIfPossible() {
        try? settingsStore.save(settings, forKey: settingsKey)
    }
}
