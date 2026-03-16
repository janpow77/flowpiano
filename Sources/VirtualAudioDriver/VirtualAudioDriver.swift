import Foundation
import AudioEngine

public struct VirtualAudioDriverStatus: Equatable, Codable {
    public var isInstalled: Bool
    public var isPublishing: Bool
    public var lastMasterLevel: Double
    public var publicationPath: String?
    public var lastError: String?

    public init(
        isInstalled: Bool = false,
        isPublishing: Bool = false,
        lastMasterLevel: Double = 0,
        publicationPath: String? = nil,
        lastError: String? = nil
    ) {
        self.isInstalled = isInstalled
        self.isPublishing = isPublishing
        self.lastMasterLevel = lastMasterLevel
        self.publicationPath = publicationPath
        self.lastError = lastError
    }
}

public struct VirtualMicrophoneFeed: Equatable, Codable {
    public var activeNotes: [Int]
    public var meters: AudioMeterState

    public init(activeNotes: [Int], meters: AudioMeterState) {
        self.activeNotes = activeNotes
        self.meters = meters
    }
}

public enum VirtualAudioDriverError: Error, Equatable {
    case notInstalled
    case audioEngineNotRunning
}

public final class VirtualAudioDriver {
    public private(set) var status: VirtualAudioDriverStatus
    public private(set) var currentFeed: VirtualMicrophoneFeed?
    private let publicationStore = VirtualAudioPublicationStore()

    public init(status: VirtualAudioDriverStatus = VirtualAudioDriverStatus()) {
        self.status = status
        self.status.publicationPath = publicationStore.outputURL.path
    }

    public func install() {
        status.isInstalled = true
        status.publicationPath = publicationStore.outputURL.path
        status.lastError = nil
    }

    public func uninstall() {
        status.isInstalled = false
        stopPublishing()
    }

    public func publish(state: AudioEngineState) throws {
        guard status.isInstalled else {
            status.lastError = "Virtual audio driver is not installed."
            throw VirtualAudioDriverError.notInstalled
        }

        guard state.isRunning else {
            status.lastError = "Audio engine is not running."
            throw VirtualAudioDriverError.audioEngineNotRunning
        }

        let feed = VirtualMicrophoneFeed(activeNotes: state.activeNotes, meters: state.meters)
        currentFeed = feed
        try publicationStore.write(feed)
        status.isPublishing = true
        status.lastMasterLevel = state.meters.masterLevel
        status.publicationPath = publicationStore.outputURL.path
        status.lastError = nil
    }

    public func stopPublishing() {
        currentFeed = nil
        status.isPublishing = false
        status.lastMasterLevel = 0
    }
}

private struct VirtualAudioPublicationStore {
    let outputURL: URL
    private let encoder = JSONEncoder()

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let runtimeDirectory = baseURL.appendingPathComponent("FlowPiano/Runtime", isDirectory: true)
        outputURL = runtimeDirectory.appendingPathComponent("virtual-microphone-feed.json")
    }

    func write(_ feed: VirtualMicrophoneFeed) throws {
        let directoryURL = outputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        let data = try encoder.encode(feed)
        try data.write(to: outputURL, options: .atomic)
    }
}
