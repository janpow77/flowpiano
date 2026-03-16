import Foundation
import MIDIEngine

public enum AudioRoutingMode: String, Codable {
    case internalOnly
    case layered
    case externalOnly
}

public struct AudioMixProfile: Equatable, Codable {
    public var pianoGain: Double
    public var speechGain: Double
    public var externalInstrumentGain: Double
    public var masterGain: Double

    public init(pianoGain: Double = 0.9, speechGain: Double = 0.8, externalInstrumentGain: Double = 0.7, masterGain: Double = 1.0) {
        self.pianoGain = AudioMixProfile.clamp(pianoGain)
        self.speechGain = AudioMixProfile.clamp(speechGain)
        self.externalInstrumentGain = AudioMixProfile.clamp(externalInstrumentGain)
        self.masterGain = AudioMixProfile.clamp(masterGain)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

public struct AudioMeterState: Equatable, Codable {
    public var pianoLevel: Double
    public var speechLevel: Double
    public var externalLevel: Double
    public var masterLevel: Double

    public init(pianoLevel: Double = 0, speechLevel: Double = 0, externalLevel: Double = 0, masterLevel: Double = 0) {
        self.pianoLevel = pianoLevel
        self.speechLevel = speechLevel
        self.externalLevel = externalLevel
        self.masterLevel = masterLevel
    }
}

public enum PianoSoundBankSource: String, Codable {
    case bundledGeneralUserGS
    case macOSSystemBank
    case unavailable
}

public struct AudioRuntimeState: Equatable, Codable {
    public var platformAudioAvailable: Bool
    public var speechInputAvailable: Bool
    public var pianoSoundBankSource: PianoSoundBankSource
    public var pianoSoundBankName: String
    public var lastError: String?

    public init(
        platformAudioAvailable: Bool = false,
        speechInputAvailable: Bool = false,
        pianoSoundBankSource: PianoSoundBankSource = .unavailable,
        pianoSoundBankName: String = "Unavailable",
        lastError: String? = nil
    ) {
        self.platformAudioAvailable = platformAudioAvailable
        self.speechInputAvailable = speechInputAvailable
        self.pianoSoundBankSource = pianoSoundBankSource
        self.pianoSoundBankName = pianoSoundBankName
        self.lastError = lastError
    }
}

public struct AudioEngineState: Equatable, Codable {
    public var isRunning: Bool
    public var internalPianoEnabled: Bool
    public var routingMode: AudioRoutingMode
    public var externalInstrumentConnected: Bool
    public var mixProfile: AudioMixProfile
    public var meters: AudioMeterState
    public var activeVelocities: [Int: Int]
    public var speechInputLevel: Double
    public var runtime: AudioRuntimeState

    public init(
        isRunning: Bool = false,
        internalPianoEnabled: Bool = true,
        routingMode: AudioRoutingMode = .internalOnly,
        externalInstrumentConnected: Bool = false,
        mixProfile: AudioMixProfile = AudioMixProfile(),
        meters: AudioMeterState = AudioMeterState(),
        activeVelocities: [Int: Int] = [:],
        speechInputLevel: Double = 0,
        runtime: AudioRuntimeState = AudioRuntimeState()
    ) {
        self.isRunning = isRunning
        self.internalPianoEnabled = internalPianoEnabled
        self.routingMode = routingMode
        self.externalInstrumentConnected = externalInstrumentConnected
        self.mixProfile = mixProfile
        self.meters = meters
        self.activeVelocities = activeVelocities
        self.speechInputLevel = speechInputLevel
        self.runtime = runtime
    }

    public var activeNotes: [Int] {
        activeVelocities.keys.sorted()
    }
}

public protocol AudioEngineProtocol {
    func start() throws
    func stop()
    func setInternalPianoEnabled(_ enabled: Bool)
    func setRoutingMode(_ mode: AudioRoutingMode)
    func setMixProfile(_ profile: AudioMixProfile)
    func setSpeechInputLevel(_ level: Double)
    func setExternalInstrumentConnected(_ connected: Bool)
    func process(_ event: MIDIEvent)
    var state: AudioEngineState { get }
}

public final class AudioEngine: AudioEngineProtocol {
    public private(set) var state = AudioEngineState()
    private let runtime = PlatformAudioRuntime()

    public init() {
        state.runtime = runtime.runtimeState
    }

    public func start() throws {
        try runtime.start(mixProfile: state.mixProfile, speechInputLevel: state.speechInputLevel)
        state.isRunning = true
        syncRuntimeState()
        updateMeters()
    }

    public func stop() {
        runtime.stop()
        state.isRunning = false
        state.activeVelocities = [:]
        syncRuntimeState()
        updateMeters()
    }

    public func setInternalPianoEnabled(_ enabled: Bool) {
        state.internalPianoEnabled = enabled
        if !enabled {
            state.activeVelocities = [:]
        }
        runtime.setInternalPianoEnabled(enabled, mixProfile: state.mixProfile)
        syncRuntimeState()
        updateMeters()
    }

    public func setRoutingMode(_ mode: AudioRoutingMode) {
        state.routingMode = mode
        if mode == .externalOnly {
            state.activeVelocities = [:]
        }
        runtime.setRoutingMode(mode, mixProfile: state.mixProfile, speechInputLevel: state.speechInputLevel)
        syncRuntimeState()
        updateMeters()
    }

    public func setMixProfile(_ profile: AudioMixProfile) {
        state.mixProfile = profile
        runtime.setMixProfile(profile, internalPianoEnabled: state.internalPianoEnabled, speechInputLevel: state.speechInputLevel)
        syncRuntimeState()
        updateMeters()
    }

    public func setSpeechInputLevel(_ level: Double) {
        state.speechInputLevel = min(max(level, 0), 1)
        runtime.setSpeechInputLevel(state.speechInputLevel)
        syncRuntimeState()
        updateMeters()
    }

    public func setExternalInstrumentConnected(_ connected: Bool) {
        state.externalInstrumentConnected = connected
        runtime.setExternalInstrumentConnected(connected, routingMode: state.routingMode, mixProfile: state.mixProfile)
        syncRuntimeState()
        updateMeters()
    }

    public func process(_ event: MIDIEvent) {
        guard state.internalPianoEnabled, state.routingMode != .externalOnly else {
            runtime.process(
                event,
                internalPianoEnabled: state.internalPianoEnabled,
                routingMode: state.routingMode
            )
            syncRuntimeState()
            updateMeters()
            return
        }

        if event.isNoteOn && event.velocity > 0 {
            state.activeVelocities[event.note] = event.velocity
        } else {
            state.activeVelocities.removeValue(forKey: event.note)
        }

        runtime.process(
            event,
            internalPianoEnabled: state.internalPianoEnabled,
            routingMode: state.routingMode
        )
        syncRuntimeState()
        updateMeters()
    }

    private func updateMeters() {
        let pianoSignal: Double
        if state.internalPianoEnabled, state.routingMode != .externalOnly, !state.activeVelocities.isEmpty {
            let averageVelocity = Double(state.activeVelocities.values.reduce(0, +)) / Double(state.activeVelocities.count)
            pianoSignal = min((averageVelocity / 127) * state.mixProfile.pianoGain, 1)
        } else {
            pianoSignal = 0
        }

        let speechSignal = min(state.speechInputLevel * state.mixProfile.speechGain, 1)

        let externalSignal: Double
        if state.externalInstrumentConnected, state.routingMode != .internalOnly {
            externalSignal = min(0.6 * state.mixProfile.externalInstrumentGain, 1)
        } else {
            externalSignal = 0
        }

        let summedSignal = pianoSignal + speechSignal + externalSignal
        let masterSignal = min(summedSignal * state.mixProfile.masterGain, 1)

        state.meters = AudioMeterState(
            pianoLevel: pianoSignal,
            speechLevel: speechSignal,
            externalLevel: externalSignal,
            masterLevel: state.isRunning ? masterSignal : 0
        )
    }

    private func syncRuntimeState() {
        state.runtime = runtime.runtimeState
    }
}
