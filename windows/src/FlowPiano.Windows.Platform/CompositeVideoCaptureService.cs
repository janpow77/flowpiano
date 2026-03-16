using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public sealed class CompositeVideoCaptureService : IWindowsVideoCaptureService
{
    private readonly IWindowsVideoCaptureService _primary;
    private readonly IWindowsVideoCaptureService _fallback;
    private IWindowsVideoCaptureService _active;

    public CompositeVideoCaptureService(IWindowsVideoCaptureService primary, IWindowsVideoCaptureService fallback)
    {
        _primary = primary;
        _fallback = fallback;
        _active = fallback;
    }

    public IReadOnlyList<CameraDevice> EnumerateCameras()
    {
        try
        {
            var primaryDevices = _primary.EnumerateCameras();
            if (primaryDevices.Count > 0)
            {
                _active = _primary;
                return primaryDevices;
            }
        }
        catch
        {
        }

        _active = _fallback;
        return _fallback.EnumerateCameras();
    }

    public VideoCapabilities QueryCapabilities() => _active.QueryCapabilities();

    public VideoRuntimeState QueryRuntimeState() => _active.QueryRuntimeState();

    public void StartCapture(CameraAssignment assignment) => _active.StartCapture(assignment);

    public void StopCapture()
    {
        _primary.StopCapture();
        _fallback.StopCapture();
    }
}
