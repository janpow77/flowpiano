param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [string]$Generator = 'Visual Studio 17 2022',
    [string]$Platform = 'x64',
    [switch]$SkipBridgeStaging
)

$ErrorActionPreference = 'Stop'

$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptsDir 'Common.ps1')

$windowsRoot = Split-Path -Parent $scriptsDir
$nativeRoot = Join-Path $windowsRoot 'native'
$buildRoot = Join-Path $nativeRoot 'out'
$configureRoot = Join-Path $buildRoot ("build-" + $Configuration.ToLowerInvariant())
$prepareScript = Join-Path $scriptsDir 'prepare_native_bridges.ps1'
$audioStageScript = Join-Path $nativeRoot 'FlowPiano.VirtualAudio.Driver\INSTALL_DRIVER_PACKAGE.ps1'

Assert-ToolAvailable -Command 'cmake' -ErrorMessage 'cmake not found. Install CMake on Windows before running this script.'

if (-not $SkipBridgeStaging -and (Test-Path $prepareScript)) {
    & $prepareScript
}

New-Item -ItemType Directory -Force -Path $configureRoot | Out-Null

Push-Location $nativeRoot
try {
    Invoke-NativeCommand -FilePath 'cmake' -Arguments @('-S', '.', '-B', $configureRoot, '-G', $Generator, '-A', $Platform)
    Invoke-NativeCommand -FilePath 'cmake' -Arguments @('--build', $configureRoot, '--config', $Configuration, '--target', 'FlowPianoVirtualCameraSource')
    Invoke-NativeCommand -FilePath 'cmake' -Arguments @('--install', $configureRoot, '--config', $Configuration)
}
finally {
    Pop-Location
}

if (Test-Path $audioStageScript) {
    & $audioStageScript -PackageRoot (Join-Path $buildRoot 'FlowPianoVirtualMic')
}
