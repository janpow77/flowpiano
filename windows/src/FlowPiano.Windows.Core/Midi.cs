namespace FlowPiano.Windows.Core;

public sealed record MidiEvent(int Note, int Velocity, bool IsNoteOn, int Channel = 0, string? SourceDeviceId = null);

public sealed record MidiDevice(string Id, string Name, bool IsAvailable = true, bool SupportsVelocity = true);

public sealed record MidiEventLogEntry(int Id, MidiEvent Event);

public sealed class MidiConnectionStatus
{
    public List<MidiDevice> Devices { get; set; } = [];
    public string? ConnectedDeviceId { get; set; }
    public bool ReconnectPending { get; set; }
    public Dictionary<int, int> ActiveVelocities { get; set; } = [];
    public List<MidiEventLogEntry> EventLog { get; set; } = [];

    public MidiDevice? ConnectedDevice => Devices.FirstOrDefault(device => device.Id == ConnectedDeviceId && device.IsAvailable);
    public bool IsConnected => ConnectedDevice is not null && !ReconnectPending;
    public IReadOnlyList<int> ActiveNotes => ActiveVelocities.Keys.OrderBy(note => note).ToArray();
}

public sealed class MidiEngine
{
    private int _nextEventId = 1;

    public MidiConnectionStatus State { get; } = new();

    public MidiEngine(IEnumerable<MidiDevice>? devices = null)
    {
        if (devices is not null)
        {
            State.Devices = devices.ToList();
        }

        AutoConnectIfNeeded();
    }

    public void UpdateAvailableDevices(IEnumerable<MidiDevice> devices)
    {
        State.Devices = devices.ToList();

        if (State.ConnectedDeviceId is not null &&
            State.Devices.All(device => device.Id != State.ConnectedDeviceId || !device.IsAvailable))
        {
            State.ReconnectPending = true;
        }

        if (State.ReconnectPending)
        {
            ReconnectIfPossible();
        }
        else
        {
            AutoConnectIfNeeded();
        }
    }

    public void Connect(string? deviceId)
    {
        if (deviceId is null)
        {
            Disconnect();
            return;
        }

        if (State.Devices.All(device => device.Id != deviceId || !device.IsAvailable))
        {
            throw new InvalidOperationException("MIDI device is unavailable.");
        }

        State.ConnectedDeviceId = deviceId;
        State.ReconnectPending = false;
    }

    public void Disconnect()
    {
        State.ConnectedDeviceId = null;
        State.ReconnectPending = false;
        State.ActiveVelocities.Clear();
    }

    public bool ReconnectIfPossible()
    {
        if (!State.ReconnectPending || State.ConnectedDeviceId is null)
        {
            return false;
        }

        if (State.Devices.Any(device => device.Id == State.ConnectedDeviceId && device.IsAvailable))
        {
            State.ReconnectPending = false;
            return true;
        }

        return false;
    }

    public void Receive(MidiEvent midiEvent)
    {
        if (!State.IsConnected)
        {
            throw new InvalidOperationException("No MIDI device is connected.");
        }

        if (midiEvent.SourceDeviceId is not null && midiEvent.SourceDeviceId != State.ConnectedDeviceId)
        {
            throw new InvalidOperationException("MIDI event came from a different device.");
        }

        if (midiEvent.IsNoteOn && midiEvent.Velocity > 0)
        {
            State.ActiveVelocities[midiEvent.Note] = midiEvent.Velocity;
        }
        else
        {
            State.ActiveVelocities.Remove(midiEvent.Note);
        }

        State.EventLog.Add(new MidiEventLogEntry(_nextEventId++, midiEvent));
        if (State.EventLog.Count > 32)
        {
            State.EventLog.RemoveRange(0, State.EventLog.Count - 32);
        }
    }

    private void AutoConnectIfNeeded()
    {
        if (State.ConnectedDeviceId is not null)
        {
            return;
        }

        State.ConnectedDeviceId = State.Devices.FirstOrDefault(device => device.IsAvailable)?.Id;
        State.ReconnectPending = false;
    }
}
