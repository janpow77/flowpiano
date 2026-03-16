param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'

$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptsDir 'Common.ps1')

$windowsRoot = Split-Path -Parent $scriptsDir
$testProjectPath = Join-Path $windowsRoot 'tests\FlowPiano.Windows.Tests\FlowPiano.Windows.Tests.csproj'

Assert-ToolAvailable -Command 'dotnet' -ErrorMessage 'dotnet SDK not found. Install .NET 8 SDK on Windows before running this script.'

$arguments = @('test', $testProjectPath, '--configuration', $Configuration, '--nologo')
if ($NoBuild) {
    $arguments += '--no-build'
}

Push-Location $windowsRoot
try {
    Invoke-NativeCommand -FilePath 'dotnet' -Arguments $arguments
}
finally {
    Pop-Location
}
