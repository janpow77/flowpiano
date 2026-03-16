param(
    [string]$RuntimeDir = (Join-Path $env:APPDATA 'FlowPiano\Runtime')
)

$ErrorActionPreference = 'Stop'

$requiredFiles = @(
    'public-output-scene.json',
    'public-output-preview.svg',
    'public-output-preview.html',
    'studio-monitor-preview.svg',
    'runtime-status.json',
    'camera-capture-session.json',
    'virtual-camera-bridge.json',
    'virtual-camera-registration.json',
    'virtual-microphone-feed.json',
    'virtual-microphone-driver-feed.json',
    'virtual-audio-driver-manifest.json'
)

Write-Host 'Checking runtime artifacts in' $RuntimeDir

$missing = @()
foreach ($file in $requiredFiles) {
    $path = Join-Path $RuntimeDir $file
    if (Test-Path $path) {
        Write-Host '[ok]' $file
    }
    else {
        Write-Warning ("Missing runtime artifact: " + $file)
        $missing += $file
    }
}

if ($missing.Count -gt 0) {
    throw ('Runtime artifacts incomplete. Missing: ' + ($missing -join ', '))
}

Write-Host 'Runtime artifact check passed.'
