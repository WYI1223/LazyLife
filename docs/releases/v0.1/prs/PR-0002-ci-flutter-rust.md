# PR-0002-ci-flutter-rust

- Proposed title: `chore(ci): add CI for Flutter + Rust (Windows + Ubuntu)`
- Status: Draft

## Goal
Protect PRs from build/test regressions.

## Deliverables
- Windows: flutter pub get/test/build windows
- Rust: fmt/clippy/test
- .github/workflows/ci.yml baseline

## Planned File Changes
- [edit] `.github/workflows/ci.yml`
- [add] `tools/ci/flutter_windows_build.ps1`
- [add] `tools/ci/rust_checks.ps1`
- [edit] `scripts/format.ps1`

## Dependencies
- PR0000, PR0001

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Basic verification/tests added
- [ ] Documentation updated if behavior changes

## Notes
- TODO
