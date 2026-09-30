param (
    [ValidateSet('Detailed', 'Normal', 'Minimal')]
    [string] $OutputFormat = 'Detailed'
)

& "$PSScriptRoot/Invoke-PesterTests.ps1" -OutputFormat $OutputFormat
exit $LASTEXITCODE
