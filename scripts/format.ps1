[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$SkipRust,
    [switch]$SkipFlutter
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

function Resolve-DartTool {
    if (Test-Tool -Name "dart") {
        return "dart"
    }

    if (-not (Test-Tool -Name "flutter")) {
        return $null
    }

    $flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $flutterCmd) {
        return $null
    }

    $flutterPath = $flutterCmd.Path
    if (-not $flutterPath) {
        $flutterPath = $flutterCmd.Definition
    }
    if (-not $flutterPath) {
        return $null
    }

    $flutterBinDir = Split-Path -Parent $flutterPath
    $candidates = @(
        (Join-Path $flutterBinDir "cache\dart-sdk\bin\dart.exe"),
        (Join-Path $flutterBinDir "cache\dart-sdk\bin\dart.bat"),
        (Join-Path $flutterBinDir "cache\dart-sdk\bin\dart")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Invoke-ToolInDir {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$Tool,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    Write-Host ""
    Write-Host "[$Label]" -ForegroundColor Cyan

    if (-not (Test-Path $WorkingDirectory)) {
        $script:Failures += "Missing directory: $WorkingDirectory"
        Write-Host "  Missing directory: $WorkingDirectory" -ForegroundColor Red
        return
    }

    if (-not (Test-Tool -Name $Tool)) {
        $toolExists = $false
        if ([System.IO.Path]::IsPathRooted($Tool)) {
            $toolExists = Test-Path $Tool
        } else {
            $toolExists = Test-Tool -Name $Tool
        }
    } else {
        $toolExists = $true
    }

    if (-not $toolExists) {
        $script:Failures += "Missing required command: $Tool"
        Write-Host "  Missing command: $Tool" -ForegroundColor Red
        return
    }

    Push-Location $WorkingDirectory
    try {
        & $Tool @Arguments
        if ($LASTEXITCODE -ne 0) {
            $script:Failures += "$Tool exited with code $LASTEXITCODE in $WorkingDirectory"
            Write-Host "  Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
        }
    } finally {
        Pop-Location
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$rustRoot = Join-Path $repoRoot "crates"
$flutterRoot = Join-Path $repoRoot "apps/lazynote_flutter"
$script:Failures = @()

Write-Host "LazyNote Format Script" -ForegroundColor Green
Write-Host "Mode: $(if ($Check) { 'check-only' } else { 'write' })"

if (-not $SkipRust) {
    $rustArgs = @("fmt", "--all")
    if ($Check) {
        $rustArgs += @("--", "--check")
    }
    Invoke-ToolInDir -Label "Rust Format" -Tool "cargo" -Arguments $rustArgs -WorkingDirectory $rustRoot
}

if (-not $SkipFlutter) {
    $dartTool = Resolve-DartTool
    if ($null -eq $dartTool) {
        $script:Failures += "Missing required command: dart (and no Flutter-embedded dart found)"
        Write-Host ""
        Write-Host "[Dart Format]" -ForegroundColor Cyan
        Write-Host "  Missing command: dart" -ForegroundColor Red
    } else {
        if ($dartTool -ne "dart") {
            Write-Host ""
            Write-Host "[Dart Tool Fallback]" -ForegroundColor Cyan
            Write-Host "  Using Dart from Flutter SDK: $dartTool"
        }

        $dartArgs = @("format", ".")
        if ($Check) {
            $dartArgs = @("format", "--output=none", "--set-exit-if-changed", ".")
        }
        Invoke-ToolInDir -Label "Dart Format" -Tool $dartTool -Arguments $dartArgs -WorkingDirectory $flutterRoot
    }
}

Write-Host ""
if ($script:Failures.Count -eq 0) {
    Write-Host "Format script completed successfully." -ForegroundColor Green
    exit 0
}

Write-Host "Format script failed:" -ForegroundColor Red
foreach ($failure in $script:Failures) {
    Write-Host "  - $failure" -ForegroundColor Red
}
exit 1
