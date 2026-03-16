import XCTest
@testable import Settings
@testable import Persistence
import Foundation

final class SettingsPersistenceTests: XCTestCase {
    func testAppSettingsRoundTripInMemoryStore() throws {
        let store = InMemorySettingsStore()
        let settings = AppSettings(
            layout: .default,
            video: VideoSettings(preferredMainCameraID: "main", preferredPiPCameraID: "pip", allowMultiCamFallback: true),
            audio: AudioSettings(useInternalPiano: true, routingPreference: .layered, pianoGain: 0.8, speechGain: 0.6, externalInstrumentGain: 0.5),
            midi: MIDISettings(preferredInputDeviceID: "keyboard-1", autoReconnect: true),
            overlay: OverlaySettings(isVisible: true, showLabels: false),
            studioMonitor: StudioMonitorSettings(notationEnabled: true, diagnosticsEnabled: true, metersEnabled: true, eventLogEnabled: false, latencyIndicatorEnabled: true),
            virtualDevices: VirtualDeviceSettings(autoPublishCamera: true, autoPublishMicrophone: false)
        )
        try store.save(settings, forKey: "settings")
        let loaded = try store.load(AppSettings.self, forKey: "settings")
        XCTAssertEqual(loaded, settings)
    }

    func testAppSettingsRoundTripFileStore() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = FileSettingsStore(directoryURL: directory)
        let settings = AppSettings()

        try store.save(settings, forKey: "settings")
        let loaded = try store.load(AppSettings.self, forKey: "settings")

        XCTAssertEqual(loaded, settings)
    }
}
