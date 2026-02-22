param(
    [string]$OutputDir = "docs/reports/v0.2.5/architecture-baseline/artifacts/frontend",
    [string]$RepoRoot = "",
    [string]$FlutterAppDir = "apps/lazynote_flutter",
    [string]$LakosTarget = "apps/lazynote_flutter/lib",
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

function Resolve-LakosExecutable {
    $lakosCommand = Get-Command lakos -ErrorAction SilentlyContinue
    if ($null -ne $lakosCommand) {
        return $lakosCommand.Source
    }

    if ($env:LOCALAPPDATA) {
        $pubLakosBat = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin\lakos.bat"
        if (Test-Path $pubLakosBat) {
            return $pubLakosBat
        }
    }

    return $null
}

function Resolve-DotExecutable {
    $dotCommand = Get-Command dot -ErrorAction SilentlyContinue
    if ($null -ne $dotCommand) {
        return $dotCommand.Source
    }
    return $null
}

$resolvedRepoRoot = Resolve-RepoRootPath -RootHint $RepoRoot
$resolvedOutputDir = Resolve-PathFromRoot -RootPath $resolvedRepoRoot -PathValue $OutputDir
$resolvedFlutterAppDir = Resolve-PathFromRoot -RootPath $resolvedRepoRoot -PathValue $FlutterAppDir

$lakosDir = Join-Path $resolvedOutputDir "lakos"
$sizeDir = Join-Path $resolvedOutputDir "size"
Ensure-Directory -PathValue $resolvedOutputDir
Ensure-Directory -PathValue $lakosDir
Ensure-Directory -PathValue $sizeDir

$summary = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    repo_root    = $resolvedRepoRoot
    output_dir   = $resolvedOutputDir
    tools        = [ordered]@{}
}

$hardFailures = New-Object System.Collections.Generic.List[string]

# lakos dependency graph
$lakosStdout = Join-Path $lakosDir "lakos.stdout.txt"
$lakosStderr = Join-Path $lakosDir "lakos.stderr.txt"
$lakosHelpStdout = Join-Path $lakosDir "lakos-help.stdout.txt"
$lakosHelpStderr = Join-Path $lakosDir "lakos-help.stderr.txt"
$lakosDotFile = Join-Path $lakosDir "lakos.dot"
$lakosSvgFile = Join-Path $lakosDir "lakos.svg"
$lakosRenderStdout = Join-Path $lakosDir "lakos-render.stdout.txt"
$lakosRenderStderr = Join-Path $lakosDir "lakos-render.stderr.txt"
$lakosStatus = [ordered]@{
    tool          = "lakos"
    available     = $false
    executed      = $false
    success       = $false
    exit_code     = $null
    target        = $LakosTarget
    args          = @("--cycles-allowed", $LakosTarget)
    stdout_file   = $lakosStdout
    stderr_file   = $lakosStderr
    help_stdout   = $lakosHelpStdout
    help_stderr   = $lakosHelpStderr
    dot_file      = $lakosDotFile
    svg_file      = $lakosSvgFile
    dot_available = $false
    render_exit_code = $null
    render_stdout = $lakosRenderStdout
    render_stderr = $lakosRenderStderr
    note          = ""
}

$lakosExecutable = Resolve-LakosExecutable
if ($null -eq $lakosExecutable) {
    $lakosStatus.note = "lakos executable not found in PATH."
} else {
    $lakosStatus.available = $true
    $lakosExitCode = Invoke-CapturedCommand `
        -FilePath $lakosExecutable `
        -ArgumentList @("--cycles-allowed", $LakosTarget) `
        -WorkingDirectory $resolvedRepoRoot `
        -StdoutPath $lakosStdout `
        -StderrPath $lakosStderr
    $lakosStatus.executed = $true
    $lakosStatus.exit_code = $lakosExitCode
    $lakosStatus.success = ($lakosExitCode -eq 0)

    if (-not $lakosStatus.success) {
        $lakosStatus.note = "lakos command failed; help output is captured for troubleshooting."
        [void](Invoke-CapturedCommand `
            -FilePath $lakosExecutable `
            -ArgumentList @() `
            -WorkingDirectory $resolvedRepoRoot `
            -StdoutPath $lakosHelpStdout `
            -StderrPath $lakosHelpStderr)
    }
}
$summary.tools.lakos = $lakosStatus
if ($StrictTools -and -not $lakosStatus.success) {
    $hardFailures.Add("lakos")
}

if ($lakosStatus.success) {
    Copy-Item -Path $lakosStdout -Destination $lakosDotFile -Force
    $dotExecutable = Resolve-DotExecutable
    if ($null -ne $dotExecutable) {
        $lakosStatus.dot_available = $true
        $renderExitCode = Invoke-CapturedCommand `
            -FilePath $dotExecutable `
            -ArgumentList @("-Tsvg", $lakosDotFile, "-o", $lakosSvgFile) `
            -WorkingDirectory $resolvedRepoRoot `
            -StdoutPath $lakosRenderStdout `
            -StderrPath $lakosRenderStderr
        $lakosStatus.render_exit_code = $renderExitCode
        if ($renderExitCode -ne 0 -and [string]::IsNullOrWhiteSpace($lakosStatus.note)) {
            $lakosStatus.note = "lakos graph render failed; inspect render stderr."
        }
    } else {
        $lakosStatus.note = "dot executable not found; lakos DOT kept for manual rendering."
    }
}

# flutter analyze-size artifacts
$sizeStatus = [ordered]@{
    tool          = "flutter-analyze-size"
    available     = $false
    success       = $false
    source_dir    = ""
    copied_files  = @()
    output_dir    = $sizeDir
    note          = ""
}
$codeSizeDir = Join-Path $resolvedFlutterAppDir "build/code-size"
$sizeStatus.source_dir = $codeSizeDir

if (Test-Path $codeSizeDir) {
    $sizeStatus.available = $true
    $sizeFiles = Get-ChildItem -Path $codeSizeDir -File | Where-Object {
        $_.Name -like "snapshot*.json" -or $_.Name -like "trace*.json"
    }
    foreach ($file in $sizeFiles) {
        Copy-Item -Path $file.FullName -Destination (Join-Path $sizeDir $file.Name) -Force
        $sizeStatus.copied_files += $file.Name
    }
    if ($sizeStatus.copied_files.Count -gt 0) {
        $sizeStatus.success = $true
    } else {
        $sizeStatus.note = "No snapshot/trace files were found under build/code-size."
    }
} else {
    $sizeStatus.note = "Source build/code-size directory was not found."
}
$summary.tools.analyze_size = $sizeStatus
if ($StrictTools -and -not $sizeStatus.success) {
    $hardFailures.Add("flutter-analyze-size")
}

$summaryPath = Join-Path $resolvedOutputDir "run-summary.json"
$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryPath -Encoding UTF8

if ($hardFailures.Count -gt 0) {
    $joinedFailures = ($hardFailures -join ", ")
    throw "Strict mode failure in frontend baseline: $joinedFailures"
}

Write-Host "Frontend baseline artifacts written to: $resolvedOutputDir"
