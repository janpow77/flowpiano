using System.Runtime.InteropServices;

namespace FlowPiano.Windows.Platform;

internal enum MfVirtualCameraType
{
    SoftwareCameraSource = 0
}

internal static class MfVirtualCameraInterop
{
    internal const int S_OK = 0;

    [DllImport("mfsensorgroup.dll", ExactSpelling = true)]
    internal static extern int MFIsVirtualCameraTypeSupported(MfVirtualCameraType type, [MarshalAs(UnmanagedType.Bool)] out bool supported);

    internal static bool IsVirtualCameraApiAvailable()
    {
        if (!OperatingSystem.IsWindowsVersionAtLeast(10, 0, 22000))
        {
            return false;
        }

        try
        {
            return NativeLibrary.TryLoad("mfsensorgroup.dll", out var handle) && Release(handle);
        }
        catch
        {
            return false;
        }
    }

    internal static bool TryQuerySoftwareCameraSupport(out bool supported, out string? error)
    {
        supported = false;
        error = null;

        if (!IsVirtualCameraApiAvailable())
        {
            error = "Media Foundation virtual camera APIs require Windows 11 build 22000 or newer.";
            return false;
        }

        try
        {
            var hr = MFIsVirtualCameraTypeSupported(MfVirtualCameraType.SoftwareCameraSource, out supported);
            if (hr == S_OK)
            {
                return true;
            }

            error = $"MFIsVirtualCameraTypeSupported failed with HRESULT 0x{hr:X8}.";
            return false;
        }
        catch (Exception exception)
        {
            error = exception.Message;
            return false;
        }
    }

    private static bool Release(IntPtr handle)
    {
        NativeLibrary.Free(handle);
        return true;
    }
}
