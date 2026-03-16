using System.Runtime.InteropServices;
using System.Text;

namespace FlowPiano.Windows.Platform;

internal static class WinMmInterop
{
    internal const int MaxProductNameLength = 32;

    internal const uint CallbackFunction = 0x00030000;
    internal const uint MmSysErrNoError = 0;
    internal const uint MimData = 0x3C3;
    internal const uint MimMoreData = 0x3CC;

    internal const ushort ModSynth = 2;
    internal const ushort ModSquareSynth = 3;
    internal const ushort ModFmSynth = 4;
    internal const ushort ModWavetable = 6;
    internal const ushort ModSoftwareSynth = 7;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    internal struct MidiInCaps
    {
        public ushort ManufacturerId;
        public ushort ProductId;
        public uint DriverVersion;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = MaxProductNameLength)]
        public string ProductName;

        public uint Support;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    internal struct MidiOutCaps
    {
        public ushort ManufacturerId;
        public ushort ProductId;
        public uint DriverVersion;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = MaxProductNameLength)]
        public string ProductName;

        public ushort Technology;
        public ushort Voices;
        public ushort Notes;
        public ushort ChannelMask;
        public uint Support;
    }

    internal delegate void MidiInProc(IntPtr midiInHandle, uint message, IntPtr instance, IntPtr param1, IntPtr param2);

    [DllImport("winmm.dll")]
    internal static extern uint midiInGetNumDevs();

    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    internal static extern uint midiInGetDevCaps(UIntPtr deviceId, out MidiInCaps caps, uint capsSize);

    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    internal static extern uint midiInOpen(out IntPtr midiInHandle, uint deviceId, MidiInProc callback, IntPtr instance, uint flags);

    [DllImport("winmm.dll")]
    internal static extern uint midiInStart(IntPtr midiInHandle);

    [DllImport("winmm.dll")]
    internal static extern uint midiInStop(IntPtr midiInHandle);

    [DllImport("winmm.dll")]
    internal static extern uint midiInReset(IntPtr midiInHandle);

    [DllImport("winmm.dll")]
    internal static extern uint midiInClose(IntPtr midiInHandle);

    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    internal static extern uint midiInGetErrorText(uint errorCode, StringBuilder text, uint textLength);

    [DllImport("winmm.dll")]
    internal static extern uint midiOutGetNumDevs();

    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    internal static extern uint midiOutGetDevCaps(UIntPtr deviceId, out MidiOutCaps caps, uint capsSize);

    [DllImport("winmm.dll")]
    internal static extern uint midiOutOpen(out IntPtr midiOutHandle, uint deviceId, IntPtr callback, IntPtr instance, uint flags);

    [DllImport("winmm.dll")]
    internal static extern uint midiOutShortMsg(IntPtr midiOutHandle, uint message);

    [DllImport("winmm.dll")]
    internal static extern uint midiOutReset(IntPtr midiOutHandle);

    [DllImport("winmm.dll")]
    internal static extern uint midiOutClose(IntPtr midiOutHandle);

    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    internal static extern uint midiOutGetErrorText(uint errorCode, StringBuilder text, uint textLength);

    [DllImport("winmm.dll")]
    internal static extern uint waveInGetNumDevs();

    [DllImport("winmm.dll")]
    internal static extern uint waveOutGetNumDevs();

    internal static uint BuildShortMessage(int status, int data1, int data2) =>
        (uint)((status & 0xFF) | ((data1 & 0x7F) << 8) | ((data2 & 0x7F) << 16));

    internal static bool IsSynthTechnology(ushort technology) =>
        technology is ModSynth or ModSquareSynth or ModFmSynth or ModWavetable or ModSoftwareSynth;

    internal static string DescribeMidiInError(uint result)
    {
        if (result == MmSysErrNoError)
        {
            return "No error.";
        }

        var buffer = new StringBuilder(256);
        return midiInGetErrorText(result, buffer, (uint)buffer.Capacity) == MmSysErrNoError
            ? buffer.ToString()
            : $"MMRESULT {result}";
    }

    internal static string DescribeMidiOutError(uint result)
    {
        if (result == MmSysErrNoError)
        {
            return "No error.";
        }

        var buffer = new StringBuilder(256);
        return midiOutGetErrorText(result, buffer, (uint)buffer.Capacity) == MmSysErrNoError
            ? buffer.ToString()
            : $"MMRESULT {result}";
    }
}
