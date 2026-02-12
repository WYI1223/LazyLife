@echo off
setlocal

cd /d "%~dp0\.."
if errorlevel 1 (
  echo Failed to enter repository root.
  exit /b 1
)

echo [1/3] Build Rust FFI library (release)...
pushd crates
cargo build -p lazynote_ffi --release
if errorlevel 1 (
  popd
  echo Rust build failed.
  exit /b 1
)
popd

echo [2/3] Resolve Flutter dependencies...
pushd apps\lazynote_flutter
flutter pub get
if errorlevel 1 (
  popd
  echo flutter pub get failed.
  exit /b 1
)

echo [3/3] Launch Flutter Windows app...
flutter run -d windows
set _run_result=%ERRORLEVEL%
popd

if not "%_run_result%"=="0" (
  echo flutter run failed.
  exit /b %_run_result%
)

echo Done.
exit /b 0
