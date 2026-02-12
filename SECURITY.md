# Security Policy

## Scope

This policy applies to:

- Source code and workflows in this repository
- Release artifacts published from this repository
- Security-sensitive integrations (for example OAuth/token handling)

## Supported Versions

Current support policy:

- `main` branch: supported
- Tagged release versions (`v*`): best-effort support until a newer minor release is available
- Unreleased personal forks: not supported

## Reporting A Vulnerability

Please **do not** open public issues for security vulnerabilities.

Preferred channel:

1. Use GitHub private vulnerability reporting (Security Advisory) for this repository.

Fallback channel:

2. Contact project maintainers privately on GitHub and include `[SECURITY]` in the title.

Please include:

- Affected component/path
- Reproduction steps or PoC
- Impact and attack preconditions
- Suggested mitigation (if any)

## Response Process

Target timelines (best effort):

- Acknowledge report: within 72 hours
- Initial triage: within 7 days
- Fix plan or mitigation note: as soon as confirmed

Severity guidance:

- Critical/High: prioritize immediate mitigation and patch
- Medium/Low: patch in normal release cycle

## Coordinated Disclosure

- We follow coordinated disclosure.
- Please avoid public disclosure until a fix or mitigation is available.
- After fix release, maintainers will publish a summary (scope, impact, remediation).

## Out Of Scope

The following are generally out of scope:

- Reports without reproducible evidence
- Security issues in third-party services outside this repository's control
- Vulnerabilities requiring unrealistic attacker assumptions

## Secret Handling Baseline

- Never commit secrets, API keys, tokens, private certificates, or `.env` secrets.
- Rotate compromised credentials immediately.
- Use platform secret stores and CI secret mechanisms.

## Dependency Security

- Keep dependencies updated with security patches.
- Validate high-impact dependency upgrades via CI before merge.
