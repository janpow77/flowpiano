import Foundation
import LayoutEngine

public struct VirtualCameraStatus: Equatable, Codable {
    public var isInstalled: Bool
    public var isPublishing: Bool
    public var lastPublishedLayerKinds: [LayerKind]
    public var publicationPath: String?
    public var lastError: String?

    public init(
        isInstalled: Bool = false,
        isPublishing: Bool = false,
        lastPublishedLayerKinds: [LayerKind] = [],
        publicationPath: String? = nil,
        lastError: String? = nil
    ) {
        self.isInstalled = isInstalled
        self.isPublishing = isPublishing
        self.lastPublishedLayerKinds = lastPublishedLayerKinds
        self.publicationPath = publicationPath
        self.lastError = lastError
    }
}

public enum VirtualCameraError: Error, Equatable {
    case notInstalled
    case invalidTarget
    case forbiddenLayers([LayerKind])
}

public final class VirtualCameraExtension {
    public private(set) var status: VirtualCameraStatus
    public private(set) var currentScene: RenderScene?
    private let publicationStore = VirtualCameraPublicationStore()

    public init(status: VirtualCameraStatus = VirtualCameraStatus()) {
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

    public func publish(scene: RenderScene) throws {
        guard status.isInstalled else {
            status.lastError = "Virtual camera is not installed."
            throw VirtualCameraError.notInstalled
        }

        guard scene.target == .publicOutput else {
            status.lastError = "Virtual camera can only publish the Public Output target."
            throw VirtualCameraError.invalidTarget
        }

        let forbiddenLayers = scene.layers.map(\.kind).filter { !$0.isPublicSafe }
        guard forbiddenLayers.isEmpty else {
            status.lastError = "Public Output contains studio-only layers."
            throw VirtualCameraError.forbiddenLayers(forbiddenLayers)
        }

        currentScene = scene
        try publicationStore.write(scene)
        status.isPublishing = true
        status.lastPublishedLayerKinds = scene.layers.map(\.kind)
        status.publicationPath = publicationStore.outputURL.path
        status.lastError = nil
    }

    public func stopPublishing() {
        currentScene = nil
        status.isPublishing = false
    }
}

private struct VirtualCameraPublicationStore {
    let outputURL: URL
    private let encoder = JSONEncoder()

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let runtimeDirectory = baseURL.appendingPathComponent("FlowPiano/Runtime", isDirectory: true)
        outputURL = runtimeDirectory.appendingPathComponent("public-output-scene.json")
    }

    func write(_ scene: RenderScene) throws {
        let directoryURL = outputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        let data = try encoder.encode(scene)
        try data.write(to: outputURL, options: .atomic)
    }
}
