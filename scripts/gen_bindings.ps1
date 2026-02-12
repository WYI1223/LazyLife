[CmdletBinding()]
param(
    [string]$ConfigFile = ".flutter_rust_bridge.yaml",
    [switch]$NoConfig,
    [string]$RustRoot = "crates/lazynote_ffi",
    [string]$RustInput = "crate::api",
    [string]$DartRoot = "apps/lazynote_flutter",
    [string]$DartOutput = "apps/lazynote_flutter/lib/core/bindings",
    [string]$COutput = "apps/lazynote_flutter/windows/runner/generated_frb.h",
    [switch]$Watch,
    [switch]$NoWeb,
    [switch]$SkipDepsCheck,
    [switch]$AllowSourcePatch,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Tool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$resolvedConfigFile = if ([System.IO.Path]::IsPathRooted($ConfigFile)) {
    $ConfigFile
} else {
    Join-Path $repoRoot $ConfigFile
}

$frbTool = $null
if (Test-Tool -Name "frb_codegen") {
    $frbTool = "frb_codegen"
} elseif (Test-Tool -Name "flutter_rust_bridge_codegen") {
    $frbTool = "flutter_rust_bridge_codegen"
} else {
    throw "Missing required command: frb_codegen (or flutter_rust_bridge_codegen)"
}

$cliOverrideParams = @(
    "RustRoot",
    "RustInput",
    "DartRoot",
    "DartOutput",
    "COutput",
    "Watch",
    "NoWeb",
    "SkipDepsCheck",
    "AllowSourcePatch"
)

$hasCliOverrides = $false
foreach ($paramName in $cliOverrideParams) {
    if ($PSBoundParameters.ContainsKey($paramName)) {
        $hasCliOverrides = $true
        break
    }
}

$useConfig = (-not $NoConfig) -and (-not $hasCliOverrides) -and (Test-Path $resolvedConfigFile)
$mode = "cli-args"

if ($useConfig) {
    $args = @(
        "generate",
        "--config-file", $resolvedConfigFile
    )
    $mode = "config-file"
} else {
    if ((-not $NoConfig) -and (-not $hasCliOverrides) -and (-not (Test-Path $resolvedConfigFile))) {
        Write-Host "Config file not found ($resolvedConfigFile). Fallback to CLI args mode." -ForegroundColor Yellow
    }

    $resolvedRustRoot = Join-Path $repoRoot $RustRoot
    $resolvedDartRoot = Join-Path $repoRoot $DartRoot
    $resolvedDartOutput = Join-Path $repoRoot $DartOutput
    $resolvedCOutput = Join-Path $repoRoot $COutput

    if (-not (Test-Path $resolvedRustRoot)) {
        throw "Rust root not found: $resolvedRustRoot"
    }

    if (-not (Test-Path $resolvedDartRoot)) {
        throw "Dart root not found: $resolvedDartRoot"
    }

    if (-not (Test-Path $resolvedDartOutput)) {
        New-Item -ItemType Directory -Path $resolvedDartOutput -Force | Out-Null
    }

    $cOutputParent = Split-Path -Parent $resolvedCOutput
    if (-not (Test-Path $cOutputParent)) {
        New-Item -ItemType Directory -Path $cOutputParent -Force | Out-Null
    }

    $args = @(
        "generate",
        "--rust-root", $resolvedRustRoot,
        "--rust-input", $RustInput,
        "--dart-root", $resolvedDartRoot,
        "--dart-output", $resolvedDartOutput,
        "--c-output", $resolvedCOutput,
        "--no-auto-upgrade-dependency"
    )

    if (-not $AllowSourcePatch) {
        $args += "--no-add-mod-to-lib"
    }

    if ($NoWeb) {
        $args += "--no-web"
    }

    if ($SkipDepsCheck) {
        $args += "--no-deps-check"
    }

    if ($Watch) {
        $args += "--watch"
    }
}

Write-Host "Generating Flutter-Rust bindings..." -ForegroundColor Green
Write-Host "Tool: $frbTool"
Write-Host "Mode: $mode"
if ($mode -eq "config-file") {
    Write-Host "Config file: $resolvedConfigFile"
}

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run command:" -ForegroundColor Cyan
    Write-Host "$frbTool $($args -join ' ')" -ForegroundColor Cyan
    exit 0
}

& $frbTool @args
if ($LASTEXITCODE -ne 0) {
    throw "Binding generation failed with exit code $LASTEXITCODE"
}

Write-Host "Binding generation completed." -ForegroundColor Green
