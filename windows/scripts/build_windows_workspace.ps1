param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [switch]$SkipTests,
    [switch]$SkipNative,
    [switch]$SkipBridgeStaging
)

$ErrorActionPreference = 'Stop'

$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptsDir 'Common.ps1')

& (Join-Path $scriptsDir 'build_managed.ps1') -Configuration $Configuration

if (-not $SkipTests) {
    & (Join-Path $scriptsDir 'test_managed.ps1') -Configuration $Configuration -NoBuild
}

if (-not $SkipNative) {
    & (Join-Path $scriptsDir 'build_native_scaffolds.ps1') -Configuration $Configuration -SkipBridgeStaging:$SkipBridgeStaging
}
