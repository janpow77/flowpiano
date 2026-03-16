import Foundation
import AudioEngine
import LayoutEngine
import MIDIEngine
import VideoEngine
import VirtualAudioDriver
import VirtualCameraExtension

#if canImport(OSLog)
import OSLog
public typealias FlowLogger = Logger
#else
public struct FlowLogger {
    public init(subsystem: String, category: String) {}
    public func debug(_ message: String) {}
    public func info(_ message: String) {}
    public func warning(_ message: String) {}
    public func error(_ message: String) {}
}
#endif

public enum DiagnosticSeverity: String, Codable {
    case info
    case warning
    case critical
}

public enum DiagnosticCode: String, Codable {
    case missingCameraPermission
    case missingMicrophonePermission
    case noCameraAvailable
    case multiCamFallback
    case noMIDIDevice
    case internalPianoDisabled
    case missingPianoSoundBank
    case platformAudioUnavailable
    case publicSceneViolation
    case virtualCameraUnavailable
    case virtualAudioUnavailable
    case setupIncomplete
    case duplicateCameraSelection
}

public struct PermissionState: Equatable, Codable {
    public var cameraGranted: Bool
    public var microphoneGranted: Bool
    public var audioOutputGranted: Bool

    public init(cameraGranted: Bool = false, microphoneGranted: Bool = false, audioOutputGranted: Bool = false) {
        self.cameraGranted = cameraGranted
        self.microphoneGranted = microphoneGranted
        self.audioOutputGranted = audioOutputGranted
    }
}

public struct DiagnosticIssue: Equatable, Codable, Identifiable {
    public var code: DiagnosticCode
    public var severity: DiagnosticSeverity
    public var message: String
    public var recoverySuggestion: String

    public var id: String {
        "\(severity.rawValue)-\(code.rawValue)"
    }

    public init(code: DiagnosticCode, severity: DiagnosticSeverity, message: String, recoverySuggestion: String) {
        self.code = code
        self.severity = severity
        self.message = message
        self.recoverySuggestion = recoverySuggestion
    }
}

public struct DiagnosticsReport: Equatable, Codable {
    public var issues: [DiagnosticIssue]
    public var isReleaseReady: Bool

    public init(issues: [DiagnosticIssue] = [], isReleaseReady: Bool = false) {
        self.issues = issues
        self.isReleaseReady = isReleaseReady
    }
}

public enum DiagnosticsLog {
    public static let app = FlowLogger(subsystem: "com.flowpiano.app", category: "app")
    public static let video = FlowLogger(subsystem: "com.flowpiano.app", category: "video")
    public static let audio = FlowLogger(subsystem: "com.flowpiano.app", category: "audio")
    public static let midi = FlowLogger(subsystem: "com.flowpiano.app", category: "midi")
    public static let layout = FlowLogger(subsystem: "com.flowpiano.app", category: "layout")
}

public enum Diagnostics {
    public static func buildReport(
        permissions: PermissionState,
        video: VideoSessionState,
        midi: MIDIConnectionStatus,
        audio: AudioEngineState,
        publicSceneViolations: [LayerKind],
        virtualCamera: VirtualCameraStatus,
        virtualAudio: VirtualAudioDriverStatus,
        setupComplete: Bool
    ) -> DiagnosticsReport {
        var issues: [DiagnosticIssue] = []

        if !permissions.cameraGranted {
            issues.append(
                DiagnosticIssue(
                    code: .missingCameraPermission,
                    severity: .critical,
                    message: "Camera permission has not been granted.",
                    recoverySuggestion: "Grant camera access before starting a lesson."
                )
            )
        }

        if !permissions.microphoneGranted {
            issues.append(
                DiagnosticIssue(
                    code: .missingMicrophonePermission,
                    severity: .critical,
                    message: "Microphone permission has not been granted.",
                    recoverySuggestion: "Grant microphone access so speech mixing can work."
                )
            )
        }

        if video.warnings.contains(.noCameraAvailable) {
            issues.append(
                DiagnosticIssue(
                    code: .noCameraAvailable,
                    severity: .critical,
                    message: "No camera is currently available.",
                    recoverySuggestion: "Connect at least one supported camera."
                )
            )
        }

        if video.warnings.contains(.multiCamUnavailable) {
            issues.append(
                DiagnosticIssue(
                    code: .multiCamFallback,
                    severity: .warning,
                    message: "MultiCam is unavailable, falling back to a single camera.",
                    recoverySuggestion: "Use a supported hardware combination or continue in single-camera mode."
                )
            )
        }

        if video.warnings.contains(.duplicateCameraSelection) {
            issues.append(
                DiagnosticIssue(
                    code: .duplicateCameraSelection,
                    severity: .warning,
                    message: "Main and PiP camera were identical, PiP was disabled.",
                    recoverySuggestion: "Choose a second camera for the keyboard view."
                )
            )
        }

        if !midi.isConnected {
            issues.append(
                DiagnosticIssue(
                    code: .noMIDIDevice,
                    severity: .warning,
                    message: "No MIDI keyboard is connected.",
                    recoverySuggestion: "Reconnect the keyboard or verify that it appears in system MIDI utilities."
                )
            )
        }

        if !audio.internalPianoEnabled && audio.routingMode == .internalOnly {
            issues.append(
                DiagnosticIssue(
                    code: .internalPianoDisabled,
                    severity: .warning,
                    message: "Internal piano mode is disabled while the app is set to internal-only audio routing.",
                    recoverySuggestion: "Enable the internal piano or switch to layered/external routing."
                )
            )
        }

        if audio.internalPianoEnabled && audio.runtime.pianoSoundBankSource == .unavailable {
            issues.append(
                DiagnosticIssue(
                    code: .missingPianoSoundBank,
                    severity: .critical,
                    message: "No internal piano sound bank is available.",
                    recoverySuggestion: "Bundle a compatible SF2/DLS piano bank or run on macOS with a readable system bank."
                )
            )
        }

        if !audio.runtime.platformAudioAvailable {
            issues.append(
                DiagnosticIssue(
                    code: .platformAudioUnavailable,
                    severity: .warning,
                    message: "The current runtime does not expose macOS audio services.",
                    recoverySuggestion: "Run FlowPiano on a Mac with AVFoundation and Core Audio available."
                )
            )
        }

        if !publicSceneViolations.isEmpty {
            let kinds = publicSceneViolations.map(\.rawValue).joined(separator: ", ")
            issues.append(
                DiagnosticIssue(
                    code: .publicSceneViolation,
                    severity: .critical,
                    message: "Public Output contains studio-only layers: \(kinds).",
                    recoverySuggestion: "Remove notation, meters, logs, latency indicators, and diagnostics from Target A."
                )
            )
        }

        if !virtualCamera.isInstalled {
            issues.append(
                DiagnosticIssue(
                    code: .virtualCameraUnavailable,
                    severity: .info,
                    message: "Virtual camera is not installed.",
                    recoverySuggestion: "Install and approve the virtual camera extension when needed."
                )
            )
        }

        if !virtualAudio.isInstalled {
            issues.append(
                DiagnosticIssue(
                    code: .virtualAudioUnavailable,
                    severity: .info,
                    message: "Virtual microphone is not installed.",
                    recoverySuggestion: "Install and approve the virtual audio driver when needed."
                )
            )
        }

        if !setupComplete {
            issues.append(
                DiagnosticIssue(
                    code: .setupIncomplete,
                    severity: .info,
                    message: "The first-run setup flow is not complete.",
                    recoverySuggestion: "Work through permissions, device selection, overlay placement, and validation steps."
                )
            )
        }

        let hasCriticalIssue = issues.contains(where: { $0.severity == .critical })
        let isReleaseReady = !hasCriticalIssue && setupComplete && audio.internalPianoEnabled && publicSceneViolations.isEmpty

        return DiagnosticsReport(issues: issues, isReleaseReady: isReleaseReady)
    }
}
