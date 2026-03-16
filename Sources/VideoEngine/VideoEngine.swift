import Foundation

public struct VideoRuntimeState: Equatable, Codable {
    public var platformVideoAvailable: Bool
    public var captureConfigured: Bool
    public var usesMultiCamCapture: Bool
    public var lastError: String?

    public init(
        platformVideoAvailable: Bool = false,
        captureConfigured: Bool = false,
        usesMultiCamCapture: Bool = false,
        lastError: String? = nil
    ) {
        self.platformVideoAvailable = platformVideoAvailable
        self.captureConfigured = captureConfigured
        self.usesMultiCamCapture = usesMultiCamCapture
        self.lastError = lastError
    }
}

public enum CameraRole: String, Codable {
    case main
    case pip
}

public enum CameraPosition: String, Codable {
    case front
    case rear
    case external
    case unknown
}

public struct CameraDevice: Equatable, Codable, Identifiable {
    public let id: String
    public var name: String
    public var position: CameraPosition
    public var isAvailable: Bool
    public var supportsHighResolution: Bool

    public init(id: String, name: String, position: CameraPosition, isAvailable: Bool = true, supportsHighResolution: Bool = true) {
        self.id = id
        self.name = name
        self.position = position
        self.isAvailable = isAvailable
        self.supportsHighResolution = supportsHighResolution
    }
}

public struct VideoCapabilities: Equatable, Codable {
    public var supportsMultiCam: Bool
    public var maxActiveCameras: Int

    public init(supportsMultiCam: Bool, maxActiveCameras: Int) {
        self.supportsMultiCam = supportsMultiCam
        self.maxActiveCameras = maxActiveCameras
    }
}

public struct CameraAssignment: Equatable, Codable {
    public var mainCameraID: String?
    public var pipCameraID: String?

    public init(mainCameraID: String? = nil, pipCameraID: String? = nil) {
        self.mainCameraID = mainCameraID
        self.pipCameraID = pipCameraID
    }
}

public enum VideoWarning: String, Codable, CaseIterable {
    case noCameraAvailable
    case mainCameraUnavailable
    case pipCameraUnavailable
    case multiCamUnavailable
    case duplicateCameraSelection
}

public enum VideoMode: String, Codable {
    case inactive
    case singleCamera
    case dualCamera
}

public struct VideoSessionState: Equatable, Codable {
    public var devices: [CameraDevice]
    public var assignment: CameraAssignment
    public var capabilities: VideoCapabilities
    public var mode: VideoMode
    public var warnings: [VideoWarning]
    public var isRunning: Bool
    public var runtime: VideoRuntimeState

    public init(
        devices: [CameraDevice] = [],
        assignment: CameraAssignment = CameraAssignment(),
        capabilities: VideoCapabilities = VideoCapabilities(supportsMultiCam: false, maxActiveCameras: 1),
        mode: VideoMode = .inactive,
        warnings: [VideoWarning] = [],
        isRunning: Bool = false,
        runtime: VideoRuntimeState = VideoRuntimeState()
    ) {
        self.devices = devices
        self.assignment = assignment
        self.capabilities = capabilities
        self.mode = mode
        self.warnings = warnings
        self.isRunning = isRunning
        self.runtime = runtime
    }

    public var mainCamera: CameraDevice? {
        devices.first(where: { $0.id == assignment.mainCameraID && $0.isAvailable })
    }

    public var pipCamera: CameraDevice? {
        devices.first(where: { $0.id == assignment.pipCameraID && $0.isAvailable })
    }
}

public enum VideoEngineError: Error {
    case noMainCameraSelected
}

public protocol VideoEngineProtocol {
    func start() throws
    func stop()
    func updateDevices(_ devices: [CameraDevice], capabilities: VideoCapabilities?)
    func selectCamera(id: String?, for role: CameraRole)
    func swapCameraRoles()
    var state: VideoSessionState { get }
}

public final class VideoEngine: VideoEngineProtocol {
    public private(set) var state: VideoSessionState
    private let runtime = PlatformVideoRuntime()

    public init(
        devices: [CameraDevice] = [],
        capabilities: VideoCapabilities = VideoCapabilities(supportsMultiCam: false, maxActiveCameras: 1)
    ) {
        state = VideoSessionState(devices: devices, capabilities: capabilities)
        state.runtime = runtime.runtimeState
        sanitizeState()
    }

    public func start() throws {
        sanitizeState()
        guard state.assignment.mainCameraID != nil else {
            throw VideoEngineError.noMainCameraSelected
        }
        try runtime.start(
            assignment: state.assignment,
            devices: state.devices,
            capabilities: state.capabilities
        )
        state.isRunning = true
        syncRuntimeState()
    }

    public func stop() {
        runtime.stop()
        state.isRunning = false
        syncRuntimeState()
    }

    public func updateDevices(_ devices: [CameraDevice], capabilities: VideoCapabilities? = nil) {
        state.devices = devices
        if let capabilities {
            state.capabilities = capabilities
        }
        sanitizeState()
        guard state.assignment.mainCameraID != nil else {
            runtime.stop()
            syncRuntimeState()
            return
        }
        if state.isRunning {
            runtime.updateConfiguration(
                assignment: state.assignment,
                devices: state.devices,
                capabilities: state.capabilities
            )
            syncRuntimeState()
        }
    }

    public func selectCamera(id: String?, for role: CameraRole) {
        switch role {
        case .main:
            state.assignment.mainCameraID = id
        case .pip:
            state.assignment.pipCameraID = id
        }
        sanitizeState()
        guard state.assignment.mainCameraID != nil else {
            runtime.stop()
            state.isRunning = false
            syncRuntimeState()
            return
        }
        if state.isRunning {
            runtime.updateConfiguration(
                assignment: state.assignment,
                devices: state.devices,
                capabilities: state.capabilities
            )
            syncRuntimeState()
        }
    }

    public func swapCameraRoles() {
        let currentMain = state.assignment.mainCameraID
        state.assignment.mainCameraID = state.assignment.pipCameraID
        state.assignment.pipCameraID = currentMain
        sanitizeState()
        guard state.assignment.mainCameraID != nil else {
            runtime.stop()
            state.isRunning = false
            syncRuntimeState()
            return
        }
        if state.isRunning {
            runtime.updateConfiguration(
                assignment: state.assignment,
                devices: state.devices,
                capabilities: state.capabilities
            )
            syncRuntimeState()
        }
    }

    private func sanitizeState() {
        var warnings: [VideoWarning] = []
        let availableDevices = state.devices.filter(\.isAvailable)

        guard !availableDevices.isEmpty else {
            state.assignment = CameraAssignment()
            state.mode = .inactive
            state.warnings = [.noCameraAvailable]
            state.isRunning = false
            return
        }

        if state.assignment.mainCameraID == nil || !availableDevices.contains(where: { $0.id == state.assignment.mainCameraID }) {
            if state.assignment.mainCameraID != nil {
                warnings.append(.mainCameraUnavailable)
            }
            state.assignment.mainCameraID = availableDevices.first?.id
        }

        if state.assignment.pipCameraID != nil && !availableDevices.contains(where: { $0.id == state.assignment.pipCameraID }) {
            warnings.append(.pipCameraUnavailable)
            state.assignment.pipCameraID = nil
        }

        if state.assignment.mainCameraID == state.assignment.pipCameraID, state.assignment.mainCameraID != nil {
            warnings.append(.duplicateCameraSelection)
            state.assignment.pipCameraID = nil
        }

        let canUseMultiCam = state.capabilities.supportsMultiCam && state.capabilities.maxActiveCameras >= 2
        if !canUseMultiCam, state.assignment.pipCameraID != nil {
            warnings.append(.multiCamUnavailable)
            state.assignment.pipCameraID = nil
        }

        if canUseMultiCam, availableDevices.count > 1, state.assignment.pipCameraID == nil {
            state.assignment.pipCameraID = availableDevices.first(where: { $0.id != state.assignment.mainCameraID })?.id
        }

        if state.assignment.mainCameraID != nil && state.assignment.pipCameraID != nil {
            state.mode = .dualCamera
        } else {
            state.mode = .singleCamera
        }

        var uniqueWarnings: [VideoWarning] = []
        for warning in warnings where !uniqueWarnings.contains(warning) {
            uniqueWarnings.append(warning)
        }
        state.warnings = uniqueWarnings
    }

    private func syncRuntimeState() {
        state.runtime = runtime.runtimeState
    }
}
