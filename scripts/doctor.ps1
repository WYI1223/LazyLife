[CmdletBinding()]
param(
    [switch]$SkipFlutterDoctor
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

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tool,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    Write-Host ""
    Write-Host "[$Label]" -ForegroundColor Cyan

    if (-not (Test-Tool -Name $Tool)) {
        $script:Failures += "Missing required command: $Tool"
        Write-Host "  Missing command: $Tool" -ForegroundColor Red
        return
    }

    & $Tool @Arguments
    if ($LASTEXITCODE -ne 0) {
        $script:Failures += "$Tool exited with code $LASTEXITCODE"
        Write-Host "  Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
}

function Show-CommandLocation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tool
    )

    Write-Host ""
    Write-Host "[Command Path: $Tool]" -ForegroundColor Cyan

    $commands = @(Get-Command $Tool -All -ErrorAction SilentlyContinue)
    if ($commands.Count -eq 0) {
        Write-Host "  Not found in PATH." -ForegroundColor Red
        return
    }

    foreach ($command in $commands) {
        $path = $command.Path
        if (-not $path) {
            $path = $command.Source
        }
        if (-not $path) {
            $path = $command.Definition
        }
        Write-Host "  $path"
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$script:Failures = @()

Write-Host "LazyNote Dev Doctor" -ForegroundColor Green
Write-Host "Repository: $repoRoot"

Invoke-External -Tool "flutter" -Arguments @("--version") -Label "Flutter Version"
Invoke-External -Tool "dart" -Arguments @("--version") -Label "Dart Version"

if (-not $SkipFlutterDoctor) {
    Invoke-External -Tool "flutter" -Arguments @("doctor", "-v") -Label "Flutter Doctor"
}

Invoke-External -Tool "rustc" -Arguments @("-V") -Label "Rustc Version"
Invoke-External -Tool "cargo" -Arguments @("-V") -Label "Cargo Version"

$frbTool = $null
if (Test-Tool -Name "frb_codegen") {
    $frbTool = "frb_codegen"
} elseif (Test-Tool -Name "flutter_rust_bridge_codegen") {
    $frbTool = "flutter_rust_bridge_codegen"
}

Write-Host ""
Write-Host "[FRB Codegen Version]" -ForegroundColor Cyan
if ($null -eq $frbTool) {
    $script:Failures += "Missing required command: frb_codegen (or flutter_rust_bridge_codegen)"
    Write-Host "  Missing command: frb_codegen / flutter_rust_bridge_codegen" -ForegroundColor Red
} else {
    & $frbTool --version
    if ($LASTEXITCODE -ne 0) {
        $script:Failures += "$frbTool exited with code $LASTEXITCODE"
        Write-Host "  Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
}

Show-CommandLocation -Tool "flutter"
Show-CommandLocation -Tool "dart"
Show-CommandLocation -Tool "cargo"
Show-CommandLocation -Tool "rustc"
if ($null -ne $frbTool) {
    Show-CommandLocation -Tool $frbTool
}

Write-Host ""
if ($script:Failures.Count -eq 0) {
    Write-Host "Doctor check passed." -ForegroundColor Green
    exit 0
}

Write-Host "Doctor check failed:" -ForegroundColor Red
foreach ($failure in $script:Failures) {
    Write-Host "  - $failure" -ForegroundColor Red
}

Write-Host ""
Write-Host "[PATH Preview]" -ForegroundColor Yellow
$pathItems = $env:PATH -split ";" | Where-Object { $_ -and $_.Trim().Length -gt 0 } | Select-Object -First 25
foreach ($item in $pathItems) {
    Write-Host "  $item"
}

exit 1
