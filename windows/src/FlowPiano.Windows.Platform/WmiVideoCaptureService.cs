using System.Management;
using System.Text.RegularExpressions;
using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public sealed class WmiVideoCaptureService : IWindowsVideoCaptureService
{
    private readonly object _gate = new();
    private IReadOnlyList<CameraDevice> _devices = Array.Empty<CameraDevice>();
    private VideoRuntimeState _runtime = new(false, false, false, "Windows video capture has not been initialized.");

    public IReadOnlyList<CameraDevice> EnumerateCameras()
    {
        lock (_gate)
        {
            return _devices = EnumerateCamerasCore();
        }
    }

    public VideoCapabilities QueryCapabilities()
    {
        lock (_gate)
        {
            var devices = _devices.Count > 0 ? _devices : EnumerateCamerasCore();
            var availableCount = devices.Count(device => device.IsAvailable);
            return new VideoCapabilities(availableCount > 1, Math.Min(availableCount, 2));
        }
    }

    public VideoRuntimeState QueryRuntimeState()
    {
        lock (_gate)
        {
            return _runtime;
        }
    }

    public void StartCapture(CameraAssignment assignment)
    {
        lock (_gate)
        {
            var devices = _devices.Count > 0 ? _devices : EnumerateCamerasCore();
            var mainSelected = assignment.MainCameraId is not null && devices.Any(device => device.Id == assignment.MainCameraId && device.IsAvailable);
            var pipSelected = assignment.PipCameraId is not null && devices.Any(device => device.Id == assignment.PipCameraId && device.IsAvailable);
            var hasLiveVideo = devices.Any(device => device.IsAvailable);

            _runtime = new VideoRuntimeState(
                hasLiveVideo,
                mainSelected,
                mainSelected && pipSelected,
                mainSelected ? null : "No live Windows camera could be configured as the main source.");
        }
    }

    public void StopCapture()
    {
        lock (_gate)
        {
            _runtime = _runtime with { CaptureConfigured = false, UsesMultiCamCapture = false };
        }
    }

    private IReadOnlyList<CameraDevice> EnumerateCamerasCore()
    {
        try
        {
            using var searcher = new ManagementObjectSearcher(
                "SELECT DeviceID, Name, PNPClass FROM Win32_PnPEntity " +
                "WHERE ConfigManagerErrorCode = 0 AND (PNPClass = 'Camera' OR PNPClass = 'Image')");

            var devices = searcher.Get()
                .Cast<ManagementObject>()
                .Select(device => new CameraDevice(
                    BuildDeviceId(device["DeviceID"]?.ToString(), device["Name"]?.ToString()),
                    NormalizeName(device["Name"]?.ToString()),
                    GuessPosition(device["Name"]?.ToString()),
                    IsAvailable: true,
                    SupportsHighResolution: true))
                .DistinctBy(device => device.Id)
                .OrderBy(device => device.Name, StringComparer.OrdinalIgnoreCase)
                .ToArray();

            if (devices.Length == 0)
            {
                _runtime = new VideoRuntimeState(false, false, false, "No live Windows cameras were discovered through WMI.");
            }
            else
            {
                _runtime = new VideoRuntimeState(true, false, false, null);
            }

            return devices;
        }
        catch (Exception exception)
        {
            _runtime = new VideoRuntimeState(false, false, false, $"Windows camera discovery failed: {exception.Message}");
            return Array.Empty<CameraDevice>();
        }
    }

    private static string BuildDeviceId(string? rawDeviceId, string? rawName)
    {
        var basis = !string.IsNullOrWhiteSpace(rawDeviceId) ? rawDeviceId : rawName ?? "unknown-camera";
        return $"wmi-camera:{basis}";
    }

    private static string NormalizeName(string? rawName)
    {
        if (string.IsNullOrWhiteSpace(rawName))
        {
            return "Windows Camera";
        }

        return Regex.Replace(rawName.Trim(), "\\s+", " ");
    }

    private static CameraPosition GuessPosition(string? name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return CameraPosition.Unknown;
        }

        var normalized = name.ToLowerInvariant();
        if (normalized.Contains("front") || normalized.Contains("integrated") || normalized.Contains("user"))
        {
            return CameraPosition.Front;
        }

        if (normalized.Contains("rear") || normalized.Contains("back") || normalized.Contains("world"))
        {
            return CameraPosition.Rear;
        }

        if (normalized.Contains("usb") || normalized.Contains("webcam") || normalized.Contains("capture"))
        {
            return CameraPosition.External;
        }

        return CameraPosition.Unknown;
    }
}
