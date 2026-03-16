param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [switch]$NoRestore
)

$ErrorActionPreference = 'Stop'

$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptsDir 'Common.ps1')

$windowsRoot = Split-Path -Parent $scriptsDir
$solutionPath = Join-Path $windowsRoot 'FlowPiano.Windows.sln'

Assert-ToolAvailable -Command 'dotnet' -ErrorMessage 'dotnet SDK not found. Install .NET 8 SDK on Windows before running this script.'

$arguments = @('build', $solutionPath, '--configuration', $Configuration, '--nologo')
if ($NoRestore) {
    $arguments += '--no-restore'
}
else {
    Invoke-NativeCommand -FilePath 'dotnet' -Arguments @('restore', $solutionPath, '--nologo')
}

Push-Location $windowsRoot
try {
    Invoke-NativeCommand -FilePath 'dotnet' -Arguments $arguments
}
finally {
    Pop-Location
}
