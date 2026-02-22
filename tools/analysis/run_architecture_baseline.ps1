param(
    [string]$OutputRoot = "docs/reports/v0.2.5/architecture-baseline/artifacts",
    [string]$RepoRoot = "",
    [switch]$SkipFrontend,
    [switch]$SkipBackend,
    [switch]$SkipBloat,
    [switch]$StrictTools
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRootPath {
    param([string]$RootHint)
    if ([string]::IsNullOrWhiteSpace($RootHint)) {
        return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    }
    return (Resolve-Path $RootHint).Path
}

function Resolve-PathFromRoot {
    param(
        [string]$RootPath,
        [string]$PathValue
    )
    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
    }
    return (Join-Path $RootPath $PathValue)
}

function Ensure-Directory {
    param([string]$PathValue)
    New-Item -ItemType Directory -Force -Path $PathValue | Out-Null
}

$resolvedRepoRoot = Resolve-RepoRootPath -RootHint $RepoRoot
$resolvedOutputRoot = Resolve-PathFromRoot -RootPath $resolvedRepoRoot -PathValue $OutputRoot
Ensure-Directory -PathValue $resolvedOutputRoot

$frontendScript = Join-Path $PSScriptRoot "run_frontend_baseline.ps1"
$backendScript = Join-Path $PSScriptRoot "run_backend_baseline.ps1"
$frontendOutput = Join-Path $resolvedOutputRoot "frontend"
$backendOutput = Join-Path $resolvedOutputRoot "backend"

$frontendExitCode = 0
$backendExitCode = 0
$frontendError = ""
$backendError = ""

if (-not $SkipFrontend) {
    try {
        & $frontendScript `
            -OutputDir $frontendOutput `
            -RepoRoot $resolvedRepoRoot `
            -StrictTools:$StrictTools
    } catch {
        $frontendExitCode = 1
        $frontendError = $_.Exception.Message
    }
}

if (-not $SkipBackend) {
    try {
        & $backendScript `
            -OutputDir $backendOutput `
            -RepoRoot $resolvedRepoRoot `
            -SkipBloat:$SkipBloat `
            -StrictTools:$StrictTools
    } catch {
        $backendExitCode = 1
        $backendError = $_.Exception.Message
    }
}

$frontendSummaryPath = Join-Path $frontendOutput "run-summary.json"
$backendSummaryPath = Join-Path $backendOutput "run-summary.json"
$frontendSummary = $null
$backendSummary = $null

if (Test-Path $frontendSummaryPath) {
    $frontendSummary = Get-Content $frontendSummaryPath -Raw | ConvertFrom-Json
}
if (Test-Path $backendSummaryPath) {
    $backendSummary = Get-Content $backendSummaryPath -Raw | ConvertFrom-Json
}

$summaryLines = New-Object System.Collections.Generic.List[string]
$summaryLines.Add("# Architecture Baseline Run Summary")
$summaryLines.Add("")
$summaryLines.Add("- Generated at: $((Get-Date).ToString("o"))")
$summaryLines.Add("- Repo root: $resolvedRepoRoot")
$summaryLines.Add("- Output root: $resolvedOutputRoot")
$summaryLines.Add("- Strict tools mode: $StrictTools")
$summaryLines.Add("- Skip frontend: $SkipFrontend")
$summaryLines.Add("- Skip backend: $SkipBackend")
$summaryLines.Add("- Skip bloat: $SkipBloat")
$summaryLines.Add("")

if (-not $SkipFrontend) {
    $summaryLines.Add("## Frontend")
    if ($frontendExitCode -eq 0) {
        $summaryLines.Add("- Status: success")
    } else {
        $summaryLines.Add("- Status: failed")
        if (-not [string]::IsNullOrWhiteSpace($frontendError)) {
            $summaryLines.Add("- Error: $frontendError")
        }
    }
    $summaryLines.Add("- Summary JSON: $frontendSummaryPath")
    if ($null -ne $frontendSummary) {
        $summaryLines.Add("- lakos success: $($frontendSummary.tools.lakos.success)")
        $summaryLines.Add("- analyze-size success: $($frontendSummary.tools.analyze_size.success)")
    }
    $summaryLines.Add("")
}

if (-not $SkipBackend) {
    $summaryLines.Add("## Backend")
    if ($backendExitCode -eq 0) {
        $summaryLines.Add("- Status: success")
    } else {
        $summaryLines.Add("- Status: failed")
        if (-not [string]::IsNullOrWhiteSpace($backendError)) {
            $summaryLines.Add("- Error: $backendError")
        }
    }
    $summaryLines.Add("- Summary JSON: $backendSummaryPath")
    if ($null -ne $backendSummary) {
        $summaryLines.Add("- cargo-modules success: $($backendSummary.tools.cargo_modules.success)")
        $summaryLines.Add("- cargo-bloat success: $($backendSummary.tools.cargo_bloat.success)")
    }
    $summaryLines.Add("")
}

$runSummaryPath = Join-Path $resolvedOutputRoot "RUN_SUMMARY.md"
$summaryLines | Set-Content -Path $runSummaryPath -Encoding UTF8

$overallFailure = ($frontendExitCode -ne 0) -or ($backendExitCode -ne 0)
if ($overallFailure) {
    throw "Architecture baseline collection failed. See $runSummaryPath"
}

Write-Host "Architecture baseline collection finished. Summary: $runSummaryPath"
