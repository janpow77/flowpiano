using System.Text.Json;
using Microsoft.Win32;
using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public sealed class MediaFoundationVirtualCameraPublisher : IWindowsVirtualCameraPublisher
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { WriteIndented = true };
    private const string CameraSourceClsid = "{5F7B1F3A-4FB8-4A35-A1F5-3B7EB4B06E41}";
    private const string FriendlyName = "FlowPiano Virtual Camera";

    public MediaFoundationVirtualCameraPublisher(string runtimeDirectory)
    {
        RuntimeDirectory = runtimeDirectory;
        PublicationPath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.PublicOutputSceneFileName);
        BridgePath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.VirtualCameraBridgeFileName);
        RegistrationManifestPath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.VirtualCameraRegistrationFileName);
        PowerShellScriptPath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.VirtualCameraRegistrationScriptFileName);
    }

    public string RuntimeDirectory { get; }
    public string RegistrationManifestPath { get; }
    public string PowerShellScriptPath { get; }

    public bool IsInstalled { get; private set; }
    public bool IsPublishing { get; private set; }
    public string PublicationPath { get; }
    public string BridgePath { get; }
    public string ManifestPath => RegistrationManifestPath;
    public string? LastError { get; private set; }

    public void Refresh()
    {
        Directory.CreateDirectory(RuntimeDirectory);

        var hasApi = MfVirtualCameraInterop.TryQuerySoftwareCameraSupport(out var supported, out var supportError);
        var sourceRegistered = IsSourceRegistered();

        IsInstalled = hasApi && supported && sourceRegistered;
        IsPublishing = false;

        if (!hasApi)
        {
            LastError = supportError;
        }
        else if (!supported)
        {
            LastError = "This Windows installation reports that software virtual cameras are not supported.";
        }
        else if (!sourceRegistered)
        {
            LastError = "Media Foundation virtual camera support is available, but the FlowPiano source CLSID is not registered.";
        }
        else
        {
            LastError = null;
        }

        WriteRegistrationManifest(hasApi, supported, sourceRegistered);
        WritePowerShellScript();
    }

    public void Publish(RenderScene scene)
    {
        Directory.CreateDirectory(RuntimeDirectory);
        File.WriteAllText(PublicationPath, JsonSerializer.Serialize(scene, JsonOptions));
        File.WriteAllText(BridgePath, JsonSerializer.Serialize(new
        {
            friendlyName = FriendlyName,
            sourceClsid = CameraSourceClsid,
            publishedAtUtc = DateTimeOffset.UtcNow,
            sceneTarget = scene.Target,
            sceneLayerKinds = scene.Layers.Select(layer => layer.Kind).ToArray(),
            publicScenePath = PublicationPath,
            captureSessionPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.VirtualCameraCaptureSessionFileName),
            previewSvgPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputPreviewSvgFileName),
            previewHtmlPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputPreviewHtmlFileName),
            runtimeStatusPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.RuntimeStatusFileName)
        }, JsonOptions));

        IsPublishing = true;
        LastError = IsInstalled ? null : LastError;
    }

    private void WriteRegistrationManifest(bool apiAvailable, bool supported, bool sourceRegistered)
    {
        File.WriteAllText(RegistrationManifestPath, JsonSerializer.Serialize(new
        {
            friendlyName = FriendlyName,
            sourceClsid = CameraSourceClsid,
            apiAvailable,
            supported,
            sourceRegistered,
            publicationPath = PublicationPath,
            bridgePath = BridgePath,
            captureSessionPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.VirtualCameraCaptureSessionFileName),
            previewSvgPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputPreviewSvgFileName),
            previewHtmlPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputPreviewHtmlFileName),
            notes = new[]
            {
                "FlowPiano writes the public scene and capture-session manifest to stable runtime paths for a future Media Foundation media-source bridge.",
                "A real COM media source implementing the source CLSID must still be built and registered on Windows."
            }
        }, JsonOptions));
    }

    private void WritePowerShellScript()
    {
        File.WriteAllText(PowerShellScriptPath, $$"""
$ErrorActionPreference = 'Stop'
$runtimeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifest = Join-Path $runtimeDir 'virtual-camera-registration.json'
Write-Host 'FlowPiano virtual camera registration helper'
Write-Host 'Manifest:' $manifest
Write-Host 'Source CLSID: {{CameraSourceClsid}}'
Write-Host 'Bridge feed:' (Join-Path $runtimeDir '{{Path.GetFileName(BridgePath)}}')
Write-Host 'Capture session:' (Join-Path $runtimeDir '{{WindowsRuntimeArtifacts.VirtualCameraCaptureSessionFileName}}')
Write-Host 'A native Media Foundation COM media source still needs to be built and registered for this CLSID.'
""");
    }

    private static bool IsSourceRegistered()
    {
        using var classesRoot = RegistryKey.OpenBaseKey(RegistryHive.ClassesRoot, RegistryView.Default);
        using var clsidKey = classesRoot.OpenSubKey($@"CLSID\{CameraSourceClsid}");
        return clsidKey is not null;
    }
}
