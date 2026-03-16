using FlowPiano.Windows.Core;
using System.Runtime.InteropServices;

namespace FlowPiano.Windows.Platform;

public sealed class WinMmAudioRuntimeService : IWindowsAudioRuntimeService, IDisposable
{
    private readonly object _gate = new();
    private readonly HashSet<int> _activeNotes = [];
    private readonly string? _bundledSoundBankPath;

    private IntPtr _midiOutHandle;
    private string? _openedSynthName;
    private string? _lastError;
    private AudioRoutingMode _routingMode = AudioRoutingMode.InternalOnly;
    private bool _internalPianoEnabled = true;

    public WinMmAudioRuntimeService(string? bundledSoundBankPath = null)
    {
        _bundledSoundBankPath = bundledSoundBankPath;
    }

    public AudioRuntimeState QueryRuntimeState()
    {
        lock (_gate)
        {
            return QueryRuntimeStateCore();
        }
    }

    public void Start(AudioMixProfile mixProfile)
    {
        lock (_gate)
        {
            StopCore();

            var synth = SelectPreferredSynth();
            if (synth is null)
            {
                _lastError = BundledSoundBankExists()
                    ? "A bundled SF2 is staged, but no Windows wavetable synth was found."
                    : "No Windows MIDI synth output is available.";
                return;
            }

            var openResult = WinMmInterop.midiOutOpen(out _midiOutHandle, synth.DeviceIndex, IntPtr.Zero, IntPtr.Zero, 0);
            if (openResult != WinMmInterop.MmSysErrNoError)
            {
                _midiOutHandle = IntPtr.Zero;
                _lastError = $"Unable to open Windows synth '{synth.Name}': {WinMmInterop.DescribeMidiOutError(openResult)}";
                return;
            }

            _openedSynthName = synth.Name;
            _lastError = null;

            SendShortMessageCore(0xC0, 0, 0);
            SetRoutingCore(_routingMode, _internalPianoEnabled);
        }
    }

    public void Stop()
    {
        lock (_gate)
        {
            StopCore();
        }
    }

    public void SetRouting(AudioRoutingMode mode, bool internalPianoEnabled)
    {
        lock (_gate)
        {
            SetRoutingCore(mode, internalPianoEnabled);
        }
    }

    public void HandleMidiEvent(MidiEvent midiEvent)
    {
        lock (_gate)
        {
            if (_midiOutHandle == IntPtr.Zero || !_internalPianoEnabled || _routingMode == AudioRoutingMode.ExternalOnly)
            {
                return;
            }

            var isNoteOn = midiEvent.IsNoteOn && midiEvent.Velocity > 0;
            var status = isNoteOn ? 0x90 | (midiEvent.Channel & 0x0F) : 0x80 | (midiEvent.Channel & 0x0F);
            var velocity = isNoteOn ? midiEvent.Velocity : 0;

            if (!SendShortMessageCore(status, midiEvent.Note, velocity))
            {
                return;
            }

            if (isNoteOn)
            {
                _activeNotes.Add(midiEvent.Note);
            }
            else
            {
                _activeNotes.Remove(midiEvent.Note);
            }
        }
    }

    public void Dispose()
    {
        Stop();
        GC.SuppressFinalize(this);
    }

    private AudioRuntimeState QueryRuntimeStateCore()
    {
        var hasWaveOutput = WinMmInterop.waveOutGetNumDevs() > 0;
        var hasSpeechInput = WinMmInterop.waveInGetNumDevs() > 0;
        var synth = _openedSynthName is not null ? new MidiSynthDevice(0, _openedSynthName) : SelectPreferredSynth();

        if (synth is not null)
        {
            return new AudioRuntimeState(
                true,
                hasSpeechInput,
                PianoSoundBankSource.WindowsSystemBank,
                synth.Name,
                _lastError);
        }

        var fallbackName = BundledSoundBankExists()
            ? Path.GetFileNameWithoutExtension(_bundledSoundBankPath)
            : "Unavailable";
        var fallbackError = _lastError ?? (BundledSoundBankExists()
            ? "A bundled SF2 is present, but no Windows synth is active."
            : "No Windows MIDI synth output is available.");

        return new AudioRuntimeState(
            hasWaveOutput,
            hasSpeechInput,
            PianoSoundBankSource.Unavailable,
            string.IsNullOrWhiteSpace(fallbackName) ? "Unavailable" : fallbackName,
            fallbackError);
    }

    private void SetRoutingCore(AudioRoutingMode mode, bool internalPianoEnabled)
    {
        _routingMode = mode;
        _internalPianoEnabled = internalPianoEnabled;

        if (!_internalPianoEnabled || _routingMode == AudioRoutingMode.ExternalOnly)
        {
            SendAllNotesOffCore();
        }
    }

    private MidiSynthDevice? SelectPreferredSynth()
    {
        var capsSize = (uint)Marshal.SizeOf<WinMmInterop.MidiOutCaps>();
        var synths = new List<MidiSynthDevice>();

        for (uint index = 0; index < WinMmInterop.midiOutGetNumDevs(); index++)
        {
            var result = WinMmInterop.midiOutGetDevCaps((UIntPtr)index, out var caps, capsSize);
            if (result != WinMmInterop.MmSysErrNoError || !WinMmInterop.IsSynthTechnology(caps.Technology))
            {
                continue;
            }

            var name = string.IsNullOrWhiteSpace(caps.ProductName) ? $"Synth Output {index + 1}" : caps.ProductName.Trim();
            synths.Add(new MidiSynthDevice(index, name));
        }

        return synths
            .OrderByDescending(device => device.Name.Contains("Microsoft GS", StringComparison.OrdinalIgnoreCase))
            .ThenByDescending(device => device.Name.Contains("Wavetable", StringComparison.OrdinalIgnoreCase))
            .ThenBy(device => device.DeviceIndex)
            .FirstOrDefault();
    }

    private bool SendShortMessageCore(int status, int data1, int data2)
    {
        if (_midiOutHandle == IntPtr.Zero)
        {
            return false;
        }

        var result = WinMmInterop.midiOutShortMsg(_midiOutHandle, WinMmInterop.BuildShortMessage(status, data1, data2));
        if (result == WinMmInterop.MmSysErrNoError)
        {
            return true;
        }

        _lastError = $"Unable to send MIDI to Windows synth '{_openedSynthName ?? "unknown"}': {WinMmInterop.DescribeMidiOutError(result)}";
        return false;
    }

    private void SendAllNotesOffCore()
    {
        if (_midiOutHandle == IntPtr.Zero)
        {
            _activeNotes.Clear();
            return;
        }

        foreach (var note in _activeNotes.ToArray())
        {
            SendShortMessageCore(0x80, note, 0);
        }

        SendShortMessageCore(0xB0, 123, 0);
        _activeNotes.Clear();
    }

    private void StopCore()
    {
        SendAllNotesOffCore();

        if (_midiOutHandle != IntPtr.Zero)
        {
            WinMmInterop.midiOutReset(_midiOutHandle);
            WinMmInterop.midiOutClose(_midiOutHandle);
        }

        _midiOutHandle = IntPtr.Zero;
        _openedSynthName = null;
    }

    private bool BundledSoundBankExists() =>
        !string.IsNullOrWhiteSpace(_bundledSoundBankPath) && File.Exists(_bundledSoundBankPath);

    private sealed record MidiSynthDevice(uint DeviceIndex, string Name);
}
