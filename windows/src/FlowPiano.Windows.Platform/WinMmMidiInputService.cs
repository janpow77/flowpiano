using FlowPiano.Windows.Core;
using System.Runtime.InteropServices;

namespace FlowPiano.Windows.Platform;

public sealed class WinMmMidiInputService : IWindowsMidiInputService, IDisposable
{
    private const string DeviceIdPrefix = "winmm-midi-in:";

    private readonly object _gate = new();
    private readonly WinMmInterop.MidiInProc _callback;
    private IntPtr _midiInHandle;
    private string? _connectedDeviceId;

    public WinMmMidiInputService()
    {
        _callback = OnMidiMessage;
    }

    public event EventHandler<MidiEvent>? MidiEventReceived;

    public IReadOnlyList<MidiDevice> EnumerateDevices()
    {
        var devices = new List<MidiDevice>();
        var deviceCount = WinMmInterop.midiInGetNumDevs();
        var capsSize = (uint)Marshal.SizeOf<WinMmInterop.MidiInCaps>();

        for (uint index = 0; index < deviceCount; index++)
        {
            var result = WinMmInterop.midiInGetDevCaps((UIntPtr)index, out var caps, capsSize);
            if (result != WinMmInterop.MmSysErrNoError)
            {
                continue;
            }

            var deviceName = string.IsNullOrWhiteSpace(caps.ProductName) ? $"MIDI Input {index + 1}" : caps.ProductName.Trim();
            devices.Add(new MidiDevice(BuildDeviceId(index), deviceName));
        }

        return devices;
    }

    public void Connect(string? deviceId)
    {
        lock (_gate)
        {
            DisconnectCore();

            if (string.IsNullOrWhiteSpace(deviceId))
            {
                return;
            }

            if (!TryParseDeviceId(deviceId, out var deviceIndex))
            {
                throw new InvalidOperationException($"Unsupported MIDI device id '{deviceId}'.");
            }

            var openResult = WinMmInterop.midiInOpen(out _midiInHandle, deviceIndex, _callback, IntPtr.Zero, WinMmInterop.CallbackFunction);
            if (openResult != WinMmInterop.MmSysErrNoError)
            {
                _midiInHandle = IntPtr.Zero;
                throw new InvalidOperationException($"Unable to open MIDI input '{deviceId}': {WinMmInterop.DescribeMidiInError(openResult)}");
            }

            var startResult = WinMmInterop.midiInStart(_midiInHandle);
            if (startResult != WinMmInterop.MmSysErrNoError)
            {
                DisconnectCore();
                throw new InvalidOperationException($"Unable to start MIDI input '{deviceId}': {WinMmInterop.DescribeMidiInError(startResult)}");
            }

            _connectedDeviceId = deviceId;
        }
    }

    public void Disconnect()
    {
        lock (_gate)
        {
            DisconnectCore();
        }
    }

    public void Dispose()
    {
        Disconnect();
        GC.SuppressFinalize(this);
    }

    private void OnMidiMessage(IntPtr midiInHandle, uint message, IntPtr instance, IntPtr param1, IntPtr param2)
    {
        if (message is not WinMmInterop.MimData and not WinMmInterop.MimMoreData)
        {
            return;
        }

        MidiEvent? midiEvent;
        string? deviceId;

        lock (_gate)
        {
            midiEvent = TryTranslateShortMessage(unchecked((uint)param1.ToInt64()));
            deviceId = _connectedDeviceId;
        }

        if (midiEvent is null || deviceId is null)
        {
            return;
        }

        try
        {
            MidiEventReceived?.Invoke(this, midiEvent with { SourceDeviceId = deviceId });
        }
        catch
        {
        }
    }

    private void DisconnectCore()
    {
        if (_midiInHandle == IntPtr.Zero)
        {
            _connectedDeviceId = null;
            return;
        }

        WinMmInterop.midiInStop(_midiInHandle);
        WinMmInterop.midiInReset(_midiInHandle);
        WinMmInterop.midiInClose(_midiInHandle);

        _midiInHandle = IntPtr.Zero;
        _connectedDeviceId = null;
    }

    private static MidiEvent? TryTranslateShortMessage(uint message)
    {
        var status = (int)(message & 0xFF);
        var command = status & 0xF0;
        var channel = status & 0x0F;
        var note = (int)((message >> 8) & 0x7F);
        var velocity = (int)((message >> 16) & 0x7F);

        return command switch
        {
            0x90 when velocity > 0 => new MidiEvent(note, velocity, true, channel),
            0x90 => new MidiEvent(note, 0, false, channel),
            0x80 => new MidiEvent(note, velocity, false, channel),
            _ => null
        };
    }

    private static string BuildDeviceId(uint deviceIndex) => $"{DeviceIdPrefix}{deviceIndex}";

    private static bool TryParseDeviceId(string deviceId, out uint deviceIndex)
    {
        deviceIndex = 0;
        return deviceId.StartsWith(DeviceIdPrefix, StringComparison.OrdinalIgnoreCase)
            && uint.TryParse(deviceId[DeviceIdPrefix.Length..], out deviceIndex);
    }
}
