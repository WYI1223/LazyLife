param(
    [string]$OutputDir = "docs/reports/v0.2.5/architecture-baseline/artifacts/backend",
    [string]$RepoRoot = "",
    [string]$CargoWorkspaceDir = "crates",
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

function Invoke-CapturedCommand {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        [string]$WorkingDirectory,
        [string]$StdoutPath,
        [string]$StderrPath
    )
    $proc = Start-Process `
        -FilePath $FilePath `
        -ArgumentList $ArgumentList `
        -WorkingDirectory $WorkingDirectory `
        -RedirectStandardOutput $StdoutPath `
        -RedirectStandardError $StderrPath `
        -NoNewWindow `
        -PassThru `
        -Wait
    return $proc.ExitCode
}

function Test-CargoSubcommand {
    param(
        [string]$CargoPath,
        [string]$Subcommand,
        [string]$WorkingDirectory,
        [string]$ProbeDir
    )
    $stdoutPath = Join-Path $ProbeDir "$Subcommand-help.stdout.txt"
    $stderrPath = Join-Path $ProbeDir "$Subcommand-help.stderr.txt"
    $exitCode = Invoke-CapturedCommand `
        -FilePath $CargoPath `
        -ArgumentList @($Subcommand, "--help") `
        -WorkingDirectory $WorkingDirectory `
        -StdoutPath $stdoutPath `
        -StderrPath $stderrPath

    $stderrText = ""
    if (Test-Path $stderrPath) {
        $stderrText = Get-Content $stderrPath -Raw -ErrorAction SilentlyContinue
    }

    $isAvailable = ($exitCode -eq 0)
    $reason = ""
    if (-not $isAvailable) {
        if ($stderrText -match "no such command") {
            $reason = "cargo subcommand '$Subcommand' is not installed."
        } else {
            $reason = "cargo subcommand '$Subcommand' probe failed (exit code $exitCode)."
        }
    }

    return [ordered]@{
        available   = $isAvailable
        exit_code   = $exitCode
        reason      = $reason
        help_stdout = $stdoutPath
        help_stderr = $stderrPath
    }
}

$resolvedRepoRoot = Resolve-RepoRootPath -RootHint $RepoRoot
$resolvedOutputDir = Resolve-PathFromRoot -RootPath $resolvedRepoRoot -PathValue $OutputDir
$resolvedWorkspaceDir = Resolve-PathFromRoot -RootPath $resolvedRepoRoot -PathValue $CargoWorkspaceDir

$modulesDir = Join-Path $resolvedOutputDir "cargo-modules"
$bloatDir = Join-Path $resolvedOutputDir "cargo-bloat"
$probeDir = Join-Path $resolvedOutputDir "tool-probes"
Ensure-Directory -PathValue $resolvedOutputDir
Ensure-Directory -PathValue $modulesDir
Ensure-Directory -PathValue $bloatDir
Ensure-Directory -PathValue $probeDir

$summary = [ordered]@{
    generated_at       = (Get-Date).ToString("o")
    repo_root          = $resolvedRepoRoot
    output_dir         = $resolvedOutputDir
    cargo_workspace    = $resolvedWorkspaceDir
    skip_bloat         = [bool]$SkipBloat
    tools              = [ordered]@{}
}

$hardFailures = New-Object System.Collections.Generic.List[string]
$packages = @("lazynote_core", "lazynote_ffi")

$cargoCommand = Get-Command cargo -ErrorAction SilentlyContinue
if ($null -eq $cargoCommand) {
    $cargoMissing = [ordered]@{
        available = $false
        reason    = "cargo executable not found in PATH."
    }
    $summary.tools.cargo = $cargoMissing
    $summaryPath = Join-Path $resolvedOutputDir "run-summary.json"
    $summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8
    throw "cargo executable not found in PATH."
}

$summary.tools.cargo = [ordered]@{
    available   = $true
    executable  = $cargoCommand.Source
}

$modulesProbe = Test-CargoSubcommand `
    -CargoPath $cargoCommand.Source `
    -Subcommand "modules" `
    -WorkingDirectory $resolvedWorkspaceDir `
    -ProbeDir $probeDir

$modulesStatus = [ordered]@{
    tool         = "cargo-modules"
    available    = $modulesProbe.available
    success      = $false
    probe        = $modulesProbe
    package_runs = @()
    note         = ""
}

if ($modulesProbe.available) {
    $allPackagesSucceeded = $true
    foreach ($package in $packages) {
        $stdoutPath = Join-Path $modulesDir "$package-tree.stdout.txt"
        $stderrPath = Join-Path $modulesDir "$package-tree.stderr.txt"
        $exitCode = Invoke-CapturedCommand `
            -FilePath $cargoCommand.Source `
            -ArgumentList @("modules", "generate", "tree", "--package", $package) `
            -WorkingDirectory $resolvedWorkspaceDir `
            -StdoutPath $stdoutPath `
            -StderrPath $stderrPath
        $isSuccess = ($exitCode -eq 0)
        if (-not $isSuccess) {
            $allPackagesSucceeded = $false
        }
        $modulesStatus.package_runs += [ordered]@{
            package     = $package
            exit_code   = $exitCode
            success     = $isSuccess
            stdout_file = $stdoutPath
            stderr_file = $stderrPath
        }
    }
    $modulesStatus.success = $allPackagesSucceeded
    if (-not $modulesStatus.success) {
        $modulesStatus.note = "One or more package runs failed; inspect stderr files."
    }
} else {
    $modulesStatus.note = $modulesProbe.reason
}

$summary.tools.cargo_modules = $modulesStatus
if ($StrictTools -and -not $modulesStatus.success) {
    $hardFailures.Add("cargo-modules")
}

$bloatProbe = Test-CargoSubcommand `
    -CargoPath $cargoCommand.Source `
    -Subcommand "bloat" `
    -WorkingDirectory $resolvedWorkspaceDir `
    -ProbeDir $probeDir

$bloatStatus = [ordered]@{
    tool         = "cargo-bloat"
    available    = $bloatProbe.available
    skipped      = [bool]$SkipBloat
    success      = $false
    probe        = $bloatProbe
    package_runs = @()
    note         = ""
}

if ($SkipBloat) {
    $bloatStatus.success = $true
    $bloatStatus.note = "Skipped by request."
} elseif ($bloatProbe.available) {
    $allBloatRunsSucceeded = $true
    foreach ($package in $packages) {
        foreach ($mode in @("crates", "functions")) {
            $stdoutPath = Join-Path $bloatDir "$package-$mode.stdout.txt"
            $stderrPath = Join-Path $bloatDir "$package-$mode.stderr.txt"
            $args = @("bloat", "--release", "--package", $package)
            if ($mode -eq "crates") {
                $args += "--crates"
            } else {
                $args += "--functions"
            }
            $exitCode = Invoke-CapturedCommand `
                -FilePath $cargoCommand.Source `
                -ArgumentList $args `
                -WorkingDirectory $resolvedWorkspaceDir `
                -StdoutPath $stdoutPath `
                -StderrPath $stderrPath
            $isSuccess = ($exitCode -eq 0)
            if (-not $isSuccess) {
                $allBloatRunsSucceeded = $false
            }
            $bloatStatus.package_runs += [ordered]@{
                package     = $package
                mode        = $mode
                exit_code   = $exitCode
                success     = $isSuccess
                stdout_file = $stdoutPath
                stderr_file = $stderrPath
            }
        }
    }
    $bloatStatus.success = $allBloatRunsSucceeded
    if (-not $bloatStatus.success) {
        $bloatStatus.note = "One or more cargo-bloat runs failed; inspect stderr files."
    }
} else {
    $bloatStatus.note = $bloatProbe.reason
}

$summary.tools.cargo_bloat = $bloatStatus
if ($StrictTools -and -not $bloatStatus.success) {
    $hardFailures.Add("cargo-bloat")
}

$summaryPath = Join-Path $resolvedOutputDir "run-summary.json"
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8

if ($hardFailures.Count -gt 0) {
    $joinedFailures = ($hardFailures -join ", ")
    throw "Strict mode failure in backend baseline: $joinedFailures"
}

Write-Host "Backend baseline artifacts written to: $resolvedOutputDir"
