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

function Resolve-DotExecutable {
    $dotCommand = Get-Command dot -ErrorAction SilentlyContinue
    if ($null -ne $dotCommand) {
        return $dotCommand.Source
    }
    return $null
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
$workspaceManifestPath = Join-Path $resolvedWorkspaceDir "Cargo.toml"

$modulesDir = Join-Path $resolvedOutputDir "cargo-modules"
$bloatDir = Join-Path $resolvedOutputDir "cargo-bloat"
$probeDir = Join-Path $resolvedOutputDir "tool-probes"
Ensure-Directory -PathValue $resolvedOutputDir
Ensure-Directory -PathValue $modulesDir
Ensure-Directory -PathValue $bloatDir
Ensure-Directory -PathValue $probeDir

# Clean stale files from previous command shapes to avoid report confusion.
Get-ChildItem -Path $modulesDir -File -Filter "*-tree.*" -ErrorAction SilentlyContinue | Remove-Item -Force

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
    dot_available = $false
    package_runs = @()
    note         = ""
}

if ($modulesProbe.available) {
    $dotExecutable = Resolve-DotExecutable
    $modulesStatus.dot_available = ($null -ne $dotExecutable)
    $allPackagesSucceeded = $true
    foreach ($package in $packages) {
        $structureStdoutPath = Join-Path $modulesDir "$package-structure.stdout.txt"
        $structureStderrPath = Join-Path $modulesDir "$package-structure.stderr.txt"
        $structureExitCode = Invoke-CapturedCommand `
            -FilePath $cargoCommand.Source `
            -ArgumentList @("modules", "structure", "--package", $package, "--manifest-path", $workspaceManifestPath) `
            -WorkingDirectory $resolvedWorkspaceDir `
            -StdoutPath $structureStdoutPath `
            -StderrPath $structureStderrPath

        $dependenciesDotPath = Join-Path $modulesDir "$package-dependencies.dot"
        $dependenciesStderrPath = Join-Path $modulesDir "$package-dependencies.stderr.txt"
        $dependenciesExitCode = Invoke-CapturedCommand `
            -FilePath $cargoCommand.Source `
            -ArgumentList @("modules", "dependencies", "--package", $package, "--manifest-path", $workspaceManifestPath) `
            -WorkingDirectory $resolvedWorkspaceDir `
            -StdoutPath $dependenciesDotPath `
            -StderrPath $dependenciesStderrPath

        $renderSvgPath = Join-Path $modulesDir "$package-dependencies.svg"
        $renderStdoutPath = Join-Path $modulesDir "$package-render.stdout.txt"
        $renderStderrPath = Join-Path $modulesDir "$package-render.stderr.txt"
        $renderExitCode = $null
        $renderSuccess = $false
        if (($dependenciesExitCode -eq 0) -and $modulesStatus.dot_available) {
            $renderExitCode = Invoke-CapturedCommand `
                -FilePath $dotExecutable `
                -ArgumentList @("-Tsvg", $dependenciesDotPath, "-o", $renderSvgPath) `
                -WorkingDirectory $resolvedWorkspaceDir `
                -StdoutPath $renderStdoutPath `
                -StderrPath $renderStderrPath
            $renderSuccess = ($renderExitCode -eq 0)
        }

        $isSuccess = ($structureExitCode -eq 0) -and ($dependenciesExitCode -eq 0)
        if ($modulesStatus.dot_available) {
            $isSuccess = $isSuccess -and $renderSuccess
        }
        if (-not $isSuccess) {
            $allPackagesSucceeded = $false
        }

        $modulesStatus.package_runs += [ordered]@{
            package                   = $package
            success                   = $isSuccess
            structure_exit_code       = $structureExitCode
            structure_stdout_file     = $structureStdoutPath
            structure_stderr_file     = $structureStderrPath
            dependencies_exit_code    = $dependenciesExitCode
            dependencies_dot_file     = $dependenciesDotPath
            dependencies_stderr_file  = $dependenciesStderrPath
            render_exit_code          = $renderExitCode
            render_success            = $renderSuccess
            render_svg_file           = $renderSvgPath
            render_stdout_file        = $renderStdoutPath
            render_stderr_file        = $renderStderrPath
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
