# API Documentation

This directory contains the API contracts for LazyNote runtime boundaries.

## Scope

- Rust FFI API exported by `crates/lazynote_ffi/src/api.rs`
- Dart-side usage contract for Single Entry flow
- Stable error-code dictionary used by UI branching

## Document Index

- `docs/api/ffi-contracts.md`: consolidated FFI contract index (including notes/tags)
- `docs/api/error-codes.md`: stable error codes and handling rules
- `docs/api/single-entry-contract.md`: Single Entry behavior contract
- `docs/api/ffi-contract-v0.1.md`: *(historical)* v0.1 FFI contracts, superseded by `ffi-contracts.md`
- `docs/api/workspace-tree-contract.md`: *(historical)* v0.2 workspace tree FFI contract, superseded by `ffi-contracts.md`

## Source of Truth

1. Implementation source of truth:
   - `crates/lazynote_ffi/src/api.rs`
   - `apps/lazynote_flutter/lib/features/entry/*`
2. Generated bindings:
   - `apps/lazynote_flutter/lib/core/bindings/api.dart`
3. Contract source of truth:
   - files in this `docs/api/` directory

## Update Rules

Update `docs/api/*` in the same PR when any of the following changes:

- FFI function signatures or return models
- stable error codes
- Single Entry command grammar or behavior boundary
- sync/async behavior of exposed APIs

See also: `docs/governance/API_COMPATIBILITY.md`.
