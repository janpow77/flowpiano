import Foundation
import HarmonyTrainer
import LayoutEngine

public enum AudioRoutingPreference: String, Codable {
    case internalOnly
    case layered
    case externalOnly
}

public struct VideoSettings: Equatable, Codable {
    public var preferredMainCameraID: String?
    public var preferredPiPCameraID: String?
    public var allowMultiCamFallback: Bool

    public init(preferredMainCameraID: String? = nil, preferredPiPCameraID: String? = nil, allowMultiCamFallback: Bool = true) {
        self.preferredMainCameraID = preferredMainCameraID
        self.preferredPiPCameraID = preferredPiPCameraID
        self.allowMultiCamFallback = allowMultiCamFallback
    }
}

public struct AudioSettings: Equatable, Codable {
    public var useInternalPiano: Bool
    public var routingPreference: AudioRoutingPreference
    public var pianoGain: Double
    public var speechGain: Double
    public var externalInstrumentGain: Double

    public init(
        useInternalPiano: Bool = true,
        routingPreference: AudioRoutingPreference = .internalOnly,
        pianoGain: Double = 0.9,
        speechGain: Double = 0.8,
        externalInstrumentGain: Double = 0.7
    ) {
        self.useInternalPiano = useInternalPiano
        self.routingPreference = routingPreference
        self.pianoGain = pianoGain
        self.speechGain = speechGain
        self.externalInstrumentGain = externalInstrumentGain
    }
}

public struct MIDISettings: Equatable, Codable {
    public var preferredInputDeviceID: String?
    public var autoReconnect: Bool

    public init(preferredInputDeviceID: String? = nil, autoReconnect: Bool = true) {
        self.preferredInputDeviceID = preferredInputDeviceID
        self.autoReconnect = autoReconnect
    }
}

public struct OverlaySettings: Equatable, Codable {
    public var isVisible: Bool
    public var showLabels: Bool

    public init(isVisible: Bool = true, showLabels: Bool = true) {
        self.isVisible = isVisible
        self.showLabels = showLabels
    }
}

public struct StudioMonitorSettings: Equatable, Codable {
    public var notationEnabled: Bool
    public var diagnosticsEnabled: Bool
    public var metersEnabled: Bool
    public var eventLogEnabled: Bool
    public var latencyIndicatorEnabled: Bool
    public var harmonyTrainerEnabled: Bool

    public init(
        notationEnabled: Bool = true,
        diagnosticsEnabled: Bool = true,
        metersEnabled: Bool = true,
        eventLogEnabled: Bool = true,
        latencyIndicatorEnabled: Bool = true,
        harmonyTrainerEnabled: Bool = false
    ) {
        self.notationEnabled = notationEnabled
        self.diagnosticsEnabled = diagnosticsEnabled
        self.metersEnabled = metersEnabled
        self.eventLogEnabled = eventLogEnabled
        self.latencyIndicatorEnabled = latencyIndicatorEnabled
        self.harmonyTrainerEnabled = harmonyTrainerEnabled
    }
}

public struct VirtualDeviceSettings: Equatable, Codable {
    public var autoPublishCamera: Bool
    public var autoPublishMicrophone: Bool

    public init(autoPublishCamera: Bool = true, autoPublishMicrophone: Bool = true) {
        self.autoPublishCamera = autoPublishCamera
        self.autoPublishMicrophone = autoPublishMicrophone
    }
}

public struct AppSettings: Equatable, Codable {
    public var layout: LayoutConfiguration
    public var video: VideoSettings
    public var audio: AudioSettings
    public var midi: MIDISettings
    public var overlay: OverlaySettings
    public var studioMonitor: StudioMonitorSettings
    public var virtualDevices: VirtualDeviceSettings
    public var harmonyTrainer: HarmonyTrainerSettings

    public init(
        layout: LayoutConfiguration = .default,
        video: VideoSettings = VideoSettings(),
        audio: AudioSettings = AudioSettings(),
        midi: MIDISettings = MIDISettings(),
        overlay: OverlaySettings = OverlaySettings(),
        studioMonitor: StudioMonitorSettings = StudioMonitorSettings(),
        virtualDevices: VirtualDeviceSettings = VirtualDeviceSettings(),
        harmonyTrainer: HarmonyTrainerSettings = HarmonyTrainerSettings()
    ) {
        self.layout = layout
        self.video = video
        self.audio = audio
        self.midi = midi
        self.overlay = overlay
        self.studioMonitor = studioMonitor
        self.virtualDevices = virtualDevices
        self.harmonyTrainer = harmonyTrainer
    }
}
