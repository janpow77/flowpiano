import Foundation

#if os(macOS) && canImport(AVFoundation)
import AVFoundation

final class PlatformVideoRuntime {
    private var session: AVCaptureSession?

    private(set) var runtimeState = VideoRuntimeState(
        platformVideoAvailable: true,
        captureConfigured: false,
        usesMultiCamCapture: false,
        lastError: nil
    )

    func start(assignment: CameraAssignment, devices: [CameraDevice], capabilities: VideoCapabilities) throws {
        let canUseMultiCam = capabilities.supportsMultiCam
            && capabilities.maxActiveCameras >= 2
            && assignment.pipCameraID != nil

        let configuredSession = AVCaptureSession()
        if !canUseMultiCam {
            configuredSession.sessionPreset = .high
        }

        let selectedIDs = [assignment.mainCameraID, canUseMultiCam ? assignment.pipCameraID : nil]
            .compactMap { $0 }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )

        for deviceID in selectedIDs {
            guard
                let device = discoverySession.devices.first(where: { $0.uniqueID == deviceID }),
                let input = try? AVCaptureDeviceInput(device: device),
                configuredSession.canAddInput(input)
            else {
                continue
            }

            configuredSession.addInput(input)
        }

        configuredSession.startRunning()
        session = configuredSession
        runtimeState.captureConfigured = true
        runtimeState.usesMultiCamCapture = canUseMultiCam
        runtimeState.lastError = nil
    }

    func stop() {
        session?.stopRunning()
        session = nil
        runtimeState.captureConfigured = false
        runtimeState.usesMultiCamCapture = false
    }

    func updateConfiguration(assignment: CameraAssignment, devices: [CameraDevice], capabilities: VideoCapabilities) {
        do {
            stop()
            try start(assignment: assignment, devices: devices, capabilities: capabilities)
        } catch {
            runtimeState.captureConfigured = false
            runtimeState.lastError = String(describing: error)
        }
    }
}
#else
final class PlatformVideoRuntime {
    private(set) var runtimeState = VideoRuntimeState(
        platformVideoAvailable: false,
        captureConfigured: false,
        usesMultiCamCapture: false,
        lastError: nil
    )

    func start(assignment: CameraAssignment, devices: [CameraDevice], capabilities: VideoCapabilities) throws {}
    func stop() {}
    func updateConfiguration(assignment: CameraAssignment, devices: [CameraDevice], capabilities: VideoCapabilities) {}
}
#endif
