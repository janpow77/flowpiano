import Foundation
import MIDIEngine

#if os(macOS) && canImport(AVFoundation) && canImport(AudioToolbox)
import AVFoundation
import AudioToolbox

enum PlatformAudioRuntimeError: Error {
    case noSoundBankAvailable
}

final class PlatformAudioRuntime {
    private let engine = AVAudioEngine()
    private let pianoSampler = AVAudioUnitSampler()
    private let speechMixer = AVAudioMixerNode()

    private var hasConfiguredGraph = false
    private var hasLoadedPianoBank = false
    private var currentMixProfile = AudioMixProfile()
    private var currentSpeechInputLevel = 0.0
    private var currentRoutingMode: AudioRoutingMode = .internalOnly
    private var externalInstrumentConnected = false

    private(set) var runtimeState = AudioRuntimeState(
        platformAudioAvailable: true,
        speechInputAvailable: false,
        pianoSoundBankSource: .unavailable,
        pianoSoundBankName: "Unavailable",
        lastError: nil
    )

    func start(mixProfile: AudioMixProfile, speechInputLevel: Double) throws {
        currentMixProfile = mixProfile
        currentSpeechInputLevel = speechInputLevel

        try configureGraphIfNeeded()
        try loadPianoSoundBankIfNeeded()
        applyMixerState(internalPianoEnabled: true)

        if !engine.isRunning {
            try engine.start()
        }

        runtimeState.lastError = nil
    }

    func stop() {
        if engine.isRunning {
            engine.stop()
        }
        pianoSampler.reset()
    }

    func setInternalPianoEnabled(_ enabled: Bool, mixProfile: AudioMixProfile) {
        currentMixProfile = mixProfile
        applyMixerState(internalPianoEnabled: enabled)
    }

    func setRoutingMode(_ mode: AudioRoutingMode, mixProfile: AudioMixProfile, speechInputLevel: Double) {
        currentRoutingMode = mode
        currentMixProfile = mixProfile
        currentSpeechInputLevel = speechInputLevel
        applyMixerState(internalPianoEnabled: true)
    }

    func setMixProfile(_ profile: AudioMixProfile, internalPianoEnabled: Bool, speechInputLevel: Double) {
        currentMixProfile = profile
        currentSpeechInputLevel = speechInputLevel
        applyMixerState(internalPianoEnabled: internalPianoEnabled)
    }

    func setSpeechInputLevel(_ level: Double) {
        currentSpeechInputLevel = level
        applyMixerState(internalPianoEnabled: true)
    }

    func setExternalInstrumentConnected(_ connected: Bool, routingMode: AudioRoutingMode, mixProfile: AudioMixProfile) {
        externalInstrumentConnected = connected
        currentRoutingMode = routingMode
        currentMixProfile = mixProfile
        applyMixerState(internalPianoEnabled: true)
    }

    func process(_ event: MIDIEvent, internalPianoEnabled: Bool, routingMode: AudioRoutingMode) {
        guard hasLoadedPianoBank else { return }

        if !internalPianoEnabled || routingMode == .externalOnly {
            if !event.isNoteOn || event.velocity == 0 {
                stopNote(event.note)
            }
            return
        }

        if event.isNoteOn && event.velocity > 0 {
            startNote(event.note, velocity: event.velocity)
        } else {
            stopNote(event.note)
        }
    }

    private func configureGraphIfNeeded() throws {
        guard !hasConfiguredGraph else { return }

        engine.attach(pianoSampler)
        engine.attach(speechMixer)

        engine.connect(pianoSampler, to: engine.mainMixerNode, format: nil)

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        if inputFormat.channelCount > 0 {
            engine.connect(inputNode, to: speechMixer, format: inputFormat)
            engine.connect(speechMixer, to: engine.mainMixerNode, format: inputFormat)
            runtimeState.speechInputAvailable = true
        } else {
            runtimeState.speechInputAvailable = false
        }

        hasConfiguredGraph = true
    }

    private func loadPianoSoundBankIfNeeded() throws {
        guard !hasLoadedPianoBank else { return }

        if let bundledBankURL = Bundle.module.url(forResource: "GeneralUser GS v1.471", withExtension: "sf2") {
            try pianoSampler.loadSoundBankInstrument(
                at: bundledBankURL,
                program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: 0
            )
            hasLoadedPianoBank = true
            runtimeState.pianoSoundBankSource = .bundledGeneralUserGS
            runtimeState.pianoSoundBankName = "GeneralUser GS v1.471"
            runtimeState.lastError = nil
            return
        }

        if let systemBankURL = Self.systemPianoBankURL() {
            try pianoSampler.loadSoundBankInstrument(
                at: systemBankURL,
                program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: 0
            )
            hasLoadedPianoBank = true
            runtimeState.pianoSoundBankSource = .macOSSystemBank
            runtimeState.pianoSoundBankName = systemBankURL.lastPathComponent
            runtimeState.lastError = nil
            return
        }

        runtimeState.pianoSoundBankSource = .unavailable
        runtimeState.pianoSoundBankName = "Unavailable"
        runtimeState.lastError = "No bundled or system piano sound bank could be loaded."
        throw PlatformAudioRuntimeError.noSoundBankAvailable
    }

    private func applyMixerState(internalPianoEnabled: Bool) {
        let pianoVolume: Float
        if internalPianoEnabled && currentRoutingMode != .externalOnly {
            pianoVolume = Float(currentMixProfile.pianoGain)
        } else {
            pianoVolume = 0
        }

        let speechMix = currentSpeechInputLevel * currentMixProfile.speechGain
        let externalMix: Double
        if externalInstrumentConnected && currentRoutingMode != .internalOnly {
            externalMix = currentMixProfile.externalInstrumentGain
        } else {
            externalMix = 0
        }

        pianoSampler.volume = pianoVolume
        speechMixer.outputVolume = Float(min(max(speechMix, externalMix), 1))
        engine.mainMixerNode.outputVolume = Float(currentMixProfile.masterGain)
    }

    private func startNote(_ note: Int, velocity: Int) {
        pianoSampler.startNote(
            UInt8(max(0, min(127, note))),
            withVelocity: UInt8(max(0, min(127, velocity))),
            onChannel: 0
        )
    }

    private func stopNote(_ note: Int) {
        pianoSampler.stopNote(UInt8(max(0, min(127, note))), onChannel: 0)
    }

    private static func systemPianoBankURL() -> URL? {
        let candidates = [
            "/System/Library/Components/DLSMusicDevice.component/Contents/Resources/DefaultBankGS.sf2",
            "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls",
            "/System/Library/Audio/Sounds/Banks/gs_instruments.dls"
        ]

        return candidates
            .map(URL.init(fileURLWithPath:))
            .first(where: { FileManager.default.fileExists(atPath: $0.path) })
    }
}
#else
final class PlatformAudioRuntime {
    private(set) var runtimeState = AudioRuntimeState(
        platformAudioAvailable: false,
        speechInputAvailable: false,
        pianoSoundBankSource: .unavailable,
        pianoSoundBankName: "Unavailable",
        lastError: nil
    )

    func start(mixProfile: AudioMixProfile, speechInputLevel: Double) throws {}
    func stop() {}
    func setInternalPianoEnabled(_ enabled: Bool, mixProfile: AudioMixProfile) {}
    func setRoutingMode(_ mode: AudioRoutingMode, mixProfile: AudioMixProfile, speechInputLevel: Double) {}
    func setMixProfile(_ profile: AudioMixProfile, internalPianoEnabled: Bool, speechInputLevel: Double) {}
    func setSpeechInputLevel(_ level: Double) {}
    func setExternalInstrumentConnected(_ connected: Bool, routingMode: AudioRoutingMode, mixProfile: AudioMixProfile) {}
    func process(_ event: MIDIEvent, internalPianoEnabled: Bool, routingMode: AudioRoutingMode) {}
}
#endif
