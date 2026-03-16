$ErrorActionPreference = 'Stop'

$runtimeDir = Join-Path $env:APPDATA 'FlowPiano\Runtime'
$nativeDir = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent

Write-Host "FlowPiano runtime dir:" $runtimeDir
Write-Host "FlowPiano native dir:" $nativeDir

$cameraManifest = Join-Path $runtimeDir 'virtual-camera-registration.json'
$cameraBridge = Join-Path $runtimeDir 'virtual-camera-bridge.json'
$cameraSession = Join-Path $runtimeDir 'camera-capture-session.json'
$publicScene = Join-Path $runtimeDir 'public-output-scene.json'
$runtimeStatus = Join-Path $runtimeDir 'runtime-status.json'
$audioManifest = Join-Path $runtimeDir 'virtual-audio-driver-manifest.json'
$audioBridge = Join-Path $runtimeDir 'virtual-microphone-driver-feed.json'
$audioFeed = Join-Path $runtimeDir 'virtual-microphone-feed.json'

if (Test-Path $cameraManifest) {
    Copy-Item $cameraManifest (Join-Path $nativeDir 'FlowPiano.VirtualCamera.Source\managed-virtual-camera-registration.json') -Force
    Write-Host 'Copied virtual-camera registration manifest.'
}
else {
    Write-Warning 'virtual-camera-registration.json not found.'
}

if (Test-Path $cameraBridge) {
    Copy-Item $cameraBridge (Join-Path $nativeDir 'FlowPiano.VirtualCamera.Source\managed-virtual-camera-bridge.json') -Force
    Write-Host 'Copied virtual-camera bridge feed.'
}
else {
    Write-Warning 'virtual-camera-bridge.json not found.'
}

if (Test-Path $cameraSession) {
    Copy-Item $cameraSession (Join-Path $nativeDir 'FlowPiano.VirtualCamera.Source\managed-camera-capture-session.json') -Force
    Write-Host 'Copied camera capture session manifest.'
}
else {
    Write-Warning 'camera-capture-session.json not found.'
}

if (Test-Path $publicScene) {
    Copy-Item $publicScene (Join-Path $nativeDir 'FlowPiano.VirtualCamera.Source\managed-public-output-scene.json') -Force
    Write-Host 'Copied public-output scene feed.'
}
else {
    Write-Warning 'public-output-scene.json not found.'
}

if (Test-Path $runtimeStatus) {
    Copy-Item $runtimeStatus (Join-Path $nativeDir 'FlowPiano.VirtualCamera.Source\managed-runtime-status.json') -Force
    Write-Host 'Copied runtime-status snapshot.'
}
else {
    Write-Warning 'runtime-status.json not found.'
}

if (Test-Path $audioManifest) {
    Copy-Item $audioManifest (Join-Path $nativeDir 'FlowPiano.VirtualAudio.Driver\managed-virtual-audio-manifest.json') -Force
    Write-Host 'Copied virtual-audio manifest.'
}
else {
    Write-Warning 'virtual-audio-driver-manifest.json not found.'
}

if (Test-Path $audioBridge) {
    Copy-Item $audioBridge (Join-Path $nativeDir 'FlowPiano.VirtualAudio.Driver\managed-virtual-audio-bridge.json') -Force
    Write-Host 'Copied virtual-audio bridge feed.'
}
else {
    Write-Warning 'virtual-microphone-driver-feed.json not found.'
}

if (Test-Path $audioFeed) {
    Copy-Item $audioFeed (Join-Path $nativeDir 'FlowPiano.VirtualAudio.Driver\managed-virtual-microphone-feed.json') -Force
    Write-Host 'Copied virtual-microphone feed.'
}
else {
    Write-Warning 'virtual-microphone-feed.json not found.'
}
