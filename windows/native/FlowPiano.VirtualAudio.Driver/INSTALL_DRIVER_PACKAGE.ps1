param(
    [string]$PackageRoot = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'out\FlowPianoVirtualMic')
)

$ErrorActionPreference = 'Stop'

$driverRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$packageDriverDir = Join-Path $PackageRoot 'driver'
$packageManagedDir = Join-Path $PackageRoot 'managed'
$runtimeFiles = @(
    'managed-virtual-audio-manifest.json',
    'managed-virtual-audio-bridge.json',
    'managed-virtual-microphone-feed.json'
)

New-Item -ItemType Directory -Force -Path $packageDriverDir | Out-Null
New-Item -ItemType Directory -Force -Path $packageManagedDir | Out-Null

Copy-Item (Join-Path $driverRoot 'FlowPianoVirtualMic.inf') $packageDriverDir -Force

foreach ($file in $runtimeFiles) {
    $source = Join-Path $driverRoot $file
    if (Test-Path $source) {
        Copy-Item $source $packageManagedDir -Force
    }
}

Set-Content -Path (Join-Path $PackageRoot 'README.txt') -Value @"
FlowPiano Virtual Microphone Driver Package

Included:
- driver\FlowPianoVirtualMic.inf
- managed\*.json bridge files if staged

Missing on purpose:
- FlowPianoVirtualMic.sys
- FlowPianoVirtualMic.cat

Next step on a real Windows driver workstation:
1. Build the signed driver binary.
2. Generate the catalog.
3. Install via pnputil or Visual Studio driver deployment tools.
"@

Write-Host 'Driver package staged at' $PackageRoot
