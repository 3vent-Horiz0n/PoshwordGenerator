#requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

<#
.SYNOPSIS
    Führt die Pester Tests mit verschiedenen Ausgabeformaten aus.
.DESCRIPTION
    Dieses Skript ermöglicht es, die Tests mit verschiedenen Ausgabeformaten zu visualisieren.
.PARAMETER OutputFormat
    Das Ausgabeformat für die Testresultate:
    - Detailed  : Sehr detaillierte Ausgabe mit allen Test-Ergebnissen (Standard)
    - Normal    : Normale Ausgabe mit Zusammenfassung
    - Minimal   : Minimalistische Ausgabe, nur Zusammenfassung
.PARAMETER Show
    Welche Ergebnisse angezeigt werden sollen:
    - All       : Alle Tests anzeigen
    - Fails     : Nur fehlgeschlagene Tests
    - Passed    : Nur bestandene Tests
.PARAMETER Tag
    Nur Tests mit einem bestimmten Tag ausführen
.EXAMPLE
    .\Invoke-PesterTests.ps1
    Führt alle Tests mit detaillierter Ausgabe aus.
.EXAMPLE
    .\Invoke-PesterTests.ps1 -OutputFormat Minimal
    Führt alle Tests mit minimaler Ausgabe aus.
.EXAMPLE
    .\Invoke-PesterTests.ps1 -OutputFormat Normal -Show Fails
    Zeigt nur fehlgeschlagene Tests im normalen Format.
#>

param(
    [ValidateSet('Detailed', 'Normal', 'Minimal')]
    [string]$OutputFormat = 'Detailed',
    
    [ValidateSet('All', 'Fails', 'Passed')]
    [string]$Show = 'All',
    
    [string[]]$Tag = @()
)

$testPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tests'

# Pester-Konfiguration erstellen
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testPath
$pesterConfig.Run.PassThru = $true

# Pester 5 uses None for silent output; the summary below remains visible.
if ($Show -ne 'All' -or $OutputFormat -eq 'Minimal') {
    $pesterConfig.Output.Verbosity = 'None'
} else {
    $pesterConfig.Output.Verbosity = $OutputFormat
}

# Tag-Filter hinzufügen, falls vorhanden
if ($Tag.Count -gt 0) {
    $pesterConfig.Filter.Tag = $Tag
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Pester Test Execution - Show: $Show | Format: $OutputFormat" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Tests ausführen (unterdrücke Standard-Output wenn nicht All)
if ($Show -eq 'All') {
    $testResult = Invoke-Pester -Configuration $pesterConfig
} else {
    # Unterdrücke die Standard-Ausgabe und zeige nur gefilterte Tests
    $testResult = Invoke-Pester -Configuration $pesterConfig 6>$null
    
    # Zeige gefilterte Tests manuell an
    $filteredTests = switch ($Show) {
        'Fails' { $testResult.Tests | Where-Object { $_.Result -eq 'Failed' } }
        'Passed' { $testResult.Tests | Where-Object { $_.Result -eq 'Passed' } }
    }
    
    foreach ($test in $filteredTests) {
        $symbol = if ($test.Result -eq 'Passed') { '✓' } else { '✗' }
        $color = if ($test.Result -eq 'Passed') { 'Green' } else { 'Red' }
        Write-Host "$symbol $($test.Name)" -ForegroundColor $color
    }
}

# Zusammenfassung anzeigen
Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Test Zusammenfassung" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

$passed = $testResult.Tests | Where-Object { $_.Result -eq 'Passed' } | Measure-Object | Select-Object -ExpandProperty Count
$failed = $testResult.Tests | Where-Object { $_.Result -eq 'Failed' } | Measure-Object | Select-Object -ExpandProperty Count
$skipped = $testResult.Tests | Where-Object { $_.Result -eq 'Skipped' } | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "  ✓ Bestanden: $passed" -ForegroundColor Green
Write-Host "  ✗ Fehlgeschlagen: $failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
Write-Host "  ⊘ Übersprungen: $skipped" -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Insgesamt: $($testResult.Tests.Count)" -ForegroundColor Cyan
Write-Host "`n"

# Exit-Code setzen basierend auf Testresultaten
if ($testResult.FailedCount -gt 0 -or $testResult.FailedContainersCount -gt 0) {
    exit 1
}
exit 0
