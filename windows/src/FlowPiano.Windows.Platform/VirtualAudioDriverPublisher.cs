using System.Text.Json;
using Microsoft.Win32;
using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public sealed class VirtualAudioDriverPublisher : IWindowsVirtualMicrophonePublisher
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { WriteIndented = true };
    private const string DriverServiceName = "FlowPianoVirtualMic";

    public VirtualAudioDriverPublisher(string runtimeDirectory)
    {
        RuntimeDirectory = runtimeDirectory;
        PublicationPath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.VirtualMicrophoneFeedFileName);
        BridgePath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.VirtualAudioDriverBridgeFileName);
        DriverManifestPath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.VirtualAudioDriverManifestFileName);
        InstallerHintPath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.VirtualAudioDriverInstallerHintFileName);
    }

    public string RuntimeDirectory { get; }
    public string DriverManifestPath { get; }
    public string InstallerHintPath { get; }

    public bool IsInstalled { get; private set; }
    public bool IsPublishing { get; private set; }
    public string PublicationPath { get; }
    public string BridgePath { get; }
    public string ManifestPath => DriverManifestPath;
    public string? LastError { get; private set; }

    public void Refresh()
    {
        Directory.CreateDirectory(RuntimeDirectory);

        IsInstalled = IsDriverRegistered();
        IsPublishing = false;
        LastError = IsInstalled ? null : "No Windows virtual audio driver service is registered for FlowPiano yet.";

        File.WriteAllText(DriverManifestPath, JsonSerializer.Serialize(new
        {
            driverServiceName = DriverServiceName,
            publicationPath = PublicationPath,
            bridgePath = BridgePath,
            previewPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.VirtualMicrophonePreviewFileName),
            notes = new[]
            {
                "This manifest describes the JSON feed that a future Windows virtual microphone driver bridge can consume.",
                "A signed Windows audio driver package still needs to be built and installed."
            }
        }, JsonOptions));

        File.WriteAllText(InstallerHintPath,
            "FlowPiano virtual microphone driver\n" +
            $"Expected service name: {DriverServiceName}\n" +
            $"Feed path: {PublicationPath}\n" +
            $"Bridge path: {BridgePath}\n" +
            "A signed Windows audio driver package still needs to be installed.\n");
    }

    public void Publish(VirtualMicrophoneFeed feed)
    {
        Directory.CreateDirectory(RuntimeDirectory);
        File.WriteAllText(PublicationPath, JsonSerializer.Serialize(feed, JsonOptions));
        File.WriteAllText(BridgePath, JsonSerializer.Serialize(new
        {
            publishedAtUtc = DateTimeOffset.UtcNow,
            rawFeedPath = PublicationPath,
            previewPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.VirtualMicrophonePreviewFileName),
            runtimeStatusPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.RuntimeStatusFileName),
            feed
        }, JsonOptions));

        IsPublishing = true;
        LastError = IsInstalled ? null : LastError;
    }

    private static bool IsDriverRegistered()
    {
        using var machine = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Default);
        using var key = machine.OpenSubKey($@"SYSTEM\CurrentControlSet\Services\{DriverServiceName}");
        return key is not null;
    }
}
