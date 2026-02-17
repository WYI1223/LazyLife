# Plugin Capability Policy (v0.2 Baseline)

## Purpose

Define auditable runtime capability declarations for extensions before sandbox
runtime is introduced.

## Capability Set

Supported runtime capability strings:

- `network`: Allow network access for provider sync and remote service calls.
- `file`: Allow local file read/write access for import/export workflows.
- `notification`: Allow posting local notifications and reminder prompts.
- `calendar`: Allow reading/writing external calendar provider data.

## Declaration Contract

Extensions declare runtime permissions in manifest field:

- `runtime_capabilities: string[]`

Rules:

- values must be one of `network|file|notification|calendar`
- values are deduplicated and validated at registration
- empty declaration is valid

## Enforcement Contract

Invocation-time authorization uses deny-by-default:

- `ExtensionRegistry::assert_runtime_capability(extension_id, capability)`
  - returns `Ok(())` only when capability is explicitly declared
  - returns `CapabilityDenied` when capability is undeclared
  - returns `ExtensionNotFound` for unknown extension ids

This is a declaration-time and registry-time policy baseline. It does not
replace process-level sandboxing.

## Auditability

Runtime capability declarations are:

- manifest-visible in code reviews
- validated during adapter registration
- queryable from registered extension snapshots
