function Assert-ToolAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage
    )

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw $ErrorMessage
    }
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [string[]]$Arguments = @()
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        $renderedArguments = ($Arguments | ForEach-Object {
            if ($_ -match '\s') {
                '"' + $_ + '"'
            }
            else {
                $_
            }
        }) -join ' '

        throw ("Command failed with exit code {0}: {1} {2}" -f $LASTEXITCODE, $FilePath, $renderedArguments)
    }
}
