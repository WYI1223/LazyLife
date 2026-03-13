# PR-0407 CI Duplication Detection Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add cross-feature duplication detection to `architecture_check.dart`, reinforce Check 1-3 failure output, and sync the current Rule E / governance workflow surfaces for PR-0407.

**Architecture:** Keep `tools/ci/architecture_check.dart` as a standalone Dart script with no new runtime dependencies. Drive the change with integration-style tests from the Flutter package that create temporary fixture files under real `lib/features/` paths, run the script as a subprocess, and assert the CLI behavior.

**Tech Stack:** Dart CLI script, Flutter test, PowerShell commands, Markdown governance docs

---

## Chunk 1: Test Harness And Red Cases

### Task 1: Add architecture-check integration tests

**Files:**
- Create: `apps/lazynote_flutter/test/tools/architecture_check_test.dart`
- Modify: `tools/ci/architecture_check.dart`
- Test: `apps/lazynote_flutter/test/tools/architecture_check_test.dart`

- [x] **Step 1: Write the failing duplication-detection test**

Create a test that:
- creates two temporary top-level feature directories under `apps/lazynote_flutter/lib/features/`
- writes two `.dart` files with `>=101` identical normalized lines
- runs `dart run ../../tools/ci/architecture_check.dart`
- expects non-zero exit code and duplication output containing `WHAT`, `WHY`, `REFERENCE`, `HOW`

- [x] **Step 2: Run the targeted test to verify RED**

Run: `flutter test test/tools/architecture_check_test.dart --plain-name "detects cross-feature duplication"`
Expected: FAIL because the current script has no duplication detector

- [x] **Step 3: Add the failing allowlist test**

Create a test that:
- uses the same duplication fixture shape
- writes a temporary `tools/ci/duplication_allowlist.yaml` entry for that file pair
- runs the script
- expects exit code `0` and a summary mentioning allowlisted duplication

- [x] **Step 4: Run the targeted allowlist test to verify RED**

Run: `flutter test test/tools/architecture_check_test.dart --plain-name "suppresses allowlisted duplication pairs"`
Expected: FAIL because allowlist support does not exist yet

- [x] **Step 5: Add the failing output-contract tests for Check 1-3**

Create tests that temporarily introduce:
- a cross-feature import violation
- a structural-layer violation
- an oversized Dart file

Each test should assert the corresponding output now includes the required `REFERENCE`/`HOW` contract.

- [x] **Step 6: Run the targeted output-contract tests to verify RED**

Run: `flutter test test/tools/architecture_check_test.dart --plain-name "prints"`
Expected: FAIL because current Check 1-3 output is too weak

## Chunk 2: Script Implementation

### Task 2: Implement duplication detection in the CI script

**Files:**
- Modify: `tools/ci/architecture_check.dart`
- Add: `tools/ci/duplication_allowlist.yaml`
- Test: `apps/lazynote_flutter/test/tools/architecture_check_test.dart`

- [x] **Step 1: Add candidate-file discovery and normalized-line helpers**

Implement helpers that:
- enumerate `lib/features/**/*.dart`
- skip generated/test paths
- resolve top-level feature names
- produce normalized lines plus original line-number mapping

- [x] **Step 2: Add the failing tests for helper-driven edge cases if missing**

If the first-pass tests do not cover comment-line normalization or same-feature exclusion, add them before continuing.

- [x] **Step 3: Implement maximal-run duplication detection**

Add:
- match result data structures
- pair comparison over different features only
- maximal-run reporting for `>=101` normalized lines

- [x] **Step 4: Implement duplication allowlist loading**

Load `tools/ci/duplication_allowlist.yaml` as a file-pair allowlist with required `reason`.

- [x] **Step 5: Wire Check N into `main()`**

Insert the new check after Structural layer and before Docs cross-reference, with summary output and failure behavior.

- [x] **Step 6: Run the duplication-focused tests to verify GREEN**

Run: `flutter test test/tools/architecture_check_test.dart --plain-name "duplication"`
Expected: PASS

### Task 3: Reinforce Check 1-3 output contract

**Files:**
- Modify: `tools/ci/architecture_check.dart`
- Test: `apps/lazynote_flutter/test/tools/architecture_check_test.dart`

- [x] **Step 1: Update Rule E failure output**

Print violation output with `REFERENCE: docs/architecture/engineering-standards.md (Rule E)` and `HOW: move shared capability to lib/shared/ or lib/core/`.

- [x] **Step 2: Update File size failure output**

Print `HOW` guidance for splitting by responsibility.

- [x] **Step 3: Update Structural layer failure output**

Print `REFERENCE: docs/architecture/engineering-standards.md (Rule A/B)` and `HOW: inject invoker / facade instead of direct raw-layer import`.

- [x] **Step 4: Run the output-contract tests to verify GREEN**

Run: `flutter test test/tools/architecture_check_test.dart --plain-name "prints"`
Expected: PASS

## Chunk 3: Docs And Governance Sync

### Task 4: Sync current docs after behavior lands

**Files:**
- Modify: `docs/architecture/engineering-standards.md`
- Modify: `docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md`
- Modify: `docs/releases/v0.4/prs/PR-0407-ci-duplication-detection.md`

- [x] **Step 1: Update Rule E wording in current engineering standards**

Describe cross-feature substantive duplication as the landed CI-enforced extension of Rule E without over-claiming final governance promotion.

- [x] **Step 2: Update the workflow ledger rows**

Mark `governance-rule-surface`, `detector-and-allowlist`, and `output-contract` as `landed` or explicit `partial` with evidence paths that point to the script/docs changes.

- [x] **Step 3: Sync PR-0407 spec reality**

Update the spec status/checklist sections to match the landed implementation state.

## Chunk 4: Verification

### Task 5: Run full verification and inspect results

**Files:**
- Verify: `tools/ci/architecture_check.dart`
- Verify: `apps/lazynote_flutter/test/tools/architecture_check_test.dart`
- Verify: `docs/architecture/engineering-standards.md`
- Verify: `docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md`

- [x] **Step 1: Run the targeted Flutter tests**

Run: `flutter test test/tools/architecture_check_test.dart`
Expected: PASS

- [x] **Step 2: Run analyzer for the Flutter package**

Run: `dart analyze`
Expected: 0 warning

- [x] **Step 3: Run the architecture check from app root**

Run:
```powershell
cd apps/lazynote_flutter
dart run ../../tools/ci/architecture_check.dart
```
Expected: PASS with no non-allowlisted violations

- [x] **Step 4: Run the architecture check from repo root**

Run: `dart run tools/ci/architecture_check.dart`
Expected: PASS

- [x] **Step 5: Inspect git diff**

Run: `git diff -- tools/ci/architecture_check.dart tools/ci/duplication_allowlist.yaml docs/architecture/engineering-standards.md docs/reports/v0.4/governance-execution/PR-0403/ci-duplication-policy-promotion-workflow.md docs/releases/v0.4/prs/PR-0407-ci-duplication-detection.md apps/lazynote_flutter/test/tools/architecture_check_test.dart`
Expected: only PR-0407 related changes
