[CmdletBinding()]
param(
    [switch]$SkipRustBuild,
    [switch]$SkipFlutterPubGet,
    [switch]$NoAnalyzeSize,
    [string]$ArtifactName = "lazynote_flutter-windows-x64.zip"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Host "==> $Name" -ForegroundColor Cyan
    & $Action
}

function Assert-LastExitCode {
    param([Parameter(Mandatory = $true)][string]$Step)
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE"
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$cratesDir = Join-Path $repoRoot "crates"
$flutterDir = Join-Path $repoRoot "apps/lazynote_flutter"
$rustDllPath = Join-Path $cratesDir "target/release/lazynote_ffi.dll"
$releaseDir = Join-Path $flutterDir "build/windows/x64/runner/Release"
$artifactDir = Join-Path $flutterDir "build/artifacts"
$artifactPath = Join-Path $artifactDir $ArtifactName
$hashPath = "$artifactPath.sha256.txt"

Invoke-Step -Name "Resolve paths" -Action {
    Write-Host "Repo root: $repoRoot"
    Write-Host "Flutter dir: $flutterDir"
}

if (-not $SkipRustBuild) {
    Invoke-Step -Name "Build Rust FFI (release)" -Action {
        Push-Location $cratesDir
        cargo build -p lazynote_ffi --release
        Assert-LastExitCode -Step "cargo build -p lazynote_ffi --release"
        Pop-Location
    }
}

if (-not (Test-Path $rustDllPath)) {
    throw "Rust FFI library not found: $rustDllPath"
}

Invoke-Step -Name "Build Flutter Windows release" -Action {
    Push-Location $flutterDir

    if (-not $SkipFlutterPubGet) {
        flutter pub get
        Assert-LastExitCode -Step "flutter pub get"
    }

    $buildArgs = @("build", "windows", "--release")
    if (-not $NoAnalyzeSize) {
        $buildArgs += @("--analyze-size", "--code-size-directory", "build/code-size")
    }
    flutter @buildArgs
    Assert-LastExitCode -Step "flutter build windows --release"

    Pop-Location
}

if (-not (Test-Path $releaseDir)) {
    throw "Release directory not found: $releaseDir"
}

Invoke-Step -Name "Copy Rust FFI DLL into release directory" -Action {
    Copy-Item -Path $rustDllPath -Destination (Join-Path $releaseDir "lazynote_ffi.dll") -Force
}

Invoke-Step -Name "Create release zip artifact" -Action {
    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
    if (Test-Path $artifactPath) {
        Remove-Item $artifactPath -Force
    }
    Compress-Archive -Path (Join-Path $releaseDir "*") -DestinationPath $artifactPath -Force
}

$hash = Get-FileHash -Algorithm SHA256 $artifactPath
"$($hash.Hash)  $ArtifactName" | Set-Content -Path $hashPath -NoNewline

Write-Host ""
Write-Host "Build bundle completed." -ForegroundColor Green
Write-Host "Artifact: $artifactPath"
Write-Host "SHA256 : $($hash.Hash)"
Write-Host "Hash file: $hashPath"
