namespace FlowPiano.Windows.Core;

public enum CameraRole
{
    Main,
    Pip
}

public enum CameraPosition
{
    Front,
    Rear,
    External,
    Unknown
}

public enum VideoWarning
{
    NoCameraAvailable,
    MainCameraUnavailable,
    PipCameraUnavailable,
    MultiCamUnavailable,
    DuplicateCameraSelection
}

public enum VideoMode
{
    Inactive,
    SingleCamera,
    DualCamera
}

public sealed record CameraDevice(string Id, string Name, CameraPosition Position, bool IsAvailable = true, bool SupportsHighResolution = true);
public sealed record VideoCapabilities(bool SupportsMultiCam, int MaxActiveCameras);
public sealed record CameraAssignment(string? MainCameraId = null, string? PipCameraId = null);
public sealed record VideoRuntimeState(bool PlatformVideoAvailable, bool CaptureConfigured, bool UsesMultiCamCapture, string? LastError = null)
{
    public static VideoRuntimeState Preview { get; } = new(true, true, true);
}

public sealed class VideoSessionState
{
    public List<CameraDevice> Devices { get; set; } = [];
    public CameraAssignment Assignment { get; set; } = new();
    public VideoCapabilities Capabilities { get; set; } = new(false, 1);
    public VideoMode Mode { get; set; } = VideoMode.Inactive;
    public List<VideoWarning> Warnings { get; set; } = [];
    public bool IsRunning { get; set; }
    public VideoRuntimeState Runtime { get; set; } = VideoRuntimeState.Preview;

    public CameraDevice? MainCamera => Devices.FirstOrDefault(device => device.Id == Assignment.MainCameraId && device.IsAvailable);
    public CameraDevice? PipCamera => Devices.FirstOrDefault(device => device.Id == Assignment.PipCameraId && device.IsAvailable);
}

public sealed class VideoEngine
{
    public VideoSessionState State { get; } = new();

    public VideoEngine(IEnumerable<CameraDevice>? devices = null, VideoCapabilities? capabilities = null)
    {
        if (devices is not null)
        {
            State.Devices = devices.ToList();
        }

        if (capabilities is not null)
        {
            State.Capabilities = capabilities;
        }

        SanitizeState();
    }

    public void Start()
    {
        SanitizeState();
        if (State.Assignment.MainCameraId is null)
        {
            throw new InvalidOperationException("No main camera selected.");
        }

        State.IsRunning = true;
    }

    public void SetRuntime(VideoRuntimeState runtime) => State.Runtime = runtime;

    public void Stop() => State.IsRunning = false;

    public void UpdateDevices(IEnumerable<CameraDevice> devices, VideoCapabilities? capabilities = null)
    {
        State.Devices = devices.ToList();
        if (capabilities is not null)
        {
            State.Capabilities = capabilities;
        }

        SanitizeState();
    }

    public void SelectCamera(string? id, CameraRole role)
    {
        State.Assignment = role switch
        {
            CameraRole.Main => State.Assignment with { MainCameraId = id },
            CameraRole.Pip => State.Assignment with { PipCameraId = id },
            _ => State.Assignment
        };

        SanitizeState();
    }

    public void SwapCameraRoles()
    {
        State.Assignment = new CameraAssignment(State.Assignment.PipCameraId, State.Assignment.MainCameraId);
        SanitizeState();
    }

    private void SanitizeState()
    {
        var warnings = new List<VideoWarning>();
        var availableDevices = State.Devices.Where(device => device.IsAvailable).ToList();

        if (availableDevices.Count == 0)
        {
            State.Assignment = new CameraAssignment();
            State.Mode = VideoMode.Inactive;
            State.Warnings = [VideoWarning.NoCameraAvailable];
            State.IsRunning = false;
            return;
        }

        if (State.Assignment.MainCameraId is null || availableDevices.All(device => device.Id != State.Assignment.MainCameraId))
        {
            if (State.Assignment.MainCameraId is not null)
            {
                warnings.Add(VideoWarning.MainCameraUnavailable);
            }

            State.Assignment = State.Assignment with { MainCameraId = availableDevices.First().Id };
        }

        if (State.Assignment.PipCameraId is not null && availableDevices.All(device => device.Id != State.Assignment.PipCameraId))
        {
            warnings.Add(VideoWarning.PipCameraUnavailable);
            State.Assignment = State.Assignment with { PipCameraId = null };
        }

        if (State.Assignment.MainCameraId is not null && State.Assignment.MainCameraId == State.Assignment.PipCameraId)
        {
            warnings.Add(VideoWarning.DuplicateCameraSelection);
            State.Assignment = State.Assignment with { PipCameraId = null };
        }

        var canUseMultiCam = State.Capabilities.SupportsMultiCam && State.Capabilities.MaxActiveCameras >= 2;
        if (!canUseMultiCam && State.Assignment.PipCameraId is not null)
        {
            warnings.Add(VideoWarning.MultiCamUnavailable);
            State.Assignment = State.Assignment with { PipCameraId = null };
        }

        if (canUseMultiCam && availableDevices.Count > 1 && State.Assignment.PipCameraId is null)
        {
            State.Assignment = State.Assignment with
            {
                PipCameraId = availableDevices.FirstOrDefault(device => device.Id != State.Assignment.MainCameraId)?.Id
            };
        }

        State.Mode = State.Assignment.MainCameraId is not null && State.Assignment.PipCameraId is not null
            ? VideoMode.DualCamera
            : VideoMode.SingleCamera;
        State.Warnings = warnings.Distinct().ToList();
    }
}
