using System.Runtime.InteropServices;
using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public sealed class MediaFoundationVideoCaptureService : IWindowsVideoCaptureService
{
    private VideoRuntimeState _runtime = new(false, false, false, "Media Foundation capture scaffold has not been initialized.");

    public IReadOnlyList<CameraDevice> EnumerateCameras()
    {
        _runtime = IsMediaFoundationAvailable()
            ? new VideoRuntimeState(true, false, false, "Media Foundation capture scaffold is present, but device activation is not implemented yet.")
            : new VideoRuntimeState(false, false, false, "Media Foundation runtime is unavailable on this system.");

        return Array.Empty<CameraDevice>();
    }

    public VideoCapabilities QueryCapabilities() => new(false, 1);

    public VideoRuntimeState QueryRuntimeState() => _runtime;

    public void StartCapture(CameraAssignment assignment)
    {
        _runtime = IsMediaFoundationAvailable()
            ? new VideoRuntimeState(true, false, false, "Media Foundation capture start is scaffolded, but frame acquisition is still pending.")
            : new VideoRuntimeState(false, false, false, "Media Foundation runtime is unavailable on this system.");
    }

    public void StopCapture()
    {
        _runtime = _runtime with { CaptureConfigured = false, UsesMultiCamCapture = false };
    }

    private static bool IsMediaFoundationAvailable()
    {
        try
        {
            return NativeLibrary.TryLoad("mfplat.dll", out var handle) && Release(handle);
        }
        catch
        {
            return false;
        }
    }

    private static bool Release(IntPtr handle)
    {
        NativeLibrary.Free(handle);
        return true;
    }
}
