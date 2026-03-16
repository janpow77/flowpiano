param(
    [string]$DllPath
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptDir 'FlowPianoVirtualCameraSource.reg.template'
$generatedRegPath = Join-Path $scriptDir 'FlowPianoVirtualCameraSource.generated.reg'

Write-Host 'FlowPiano Virtual Camera Source'
Write-Host 'This scaffold does not self-register yet.'
Write-Host 'Expected staged files:'
Write-Host ' - managed-virtual-camera-registration.json'
Write-Host ' - managed-virtual-camera-bridge.json'
Write-Host ' - managed-camera-capture-session.json'
Write-Host ' - managed-public-output-scene.json'

if ($DllPath) {
    if (-not (Test-Path $DllPath)) {
        throw ('DLL path not found: ' + $DllPath)
    }

    $escapedDllPath = $DllPath.Replace('\', '\\')
    $template = Get-Content $templatePath -Raw
    $template.Replace('{{DLL_PATH}}', $escapedDllPath) | Set-Content $generatedRegPath

    Write-Host 'Generated registry template:' $generatedRegPath
    Write-Host 'Import manually after verifying the DLL path:'
    Write-Host '  reg import' $generatedRegPath
}

Write-Host 'Next step: implement the Media Foundation COM source and then add proper COM registration for CLSID {5F7B1F3A-4FB8-4A35-A1F5-3B7EB4B06E41}.'
