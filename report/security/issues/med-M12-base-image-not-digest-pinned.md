# Medium · M-12 · Container base images use mutable tags

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-829
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `Dockerfile`
  - `docker/openclaw-smoke/Dockerfile`
  - `docker/Dockerfile.onboard-smoke`
  - `docker/untrusted-review/Dockerfile`
  - `packages/plugins/sandbox-providers/cloudflare/bridge-template/Dockerfile`

## Summary

`FROM node:22-alpine`, `lts-trixie-slim`, `24.04`,
`cloudflare/sandbox:0.7.0` — none are digest-pinned.

## Impact

Supply-chain risk if an upstream tag is re-pushed.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Pin via `@sha256:...`; rotate with Renovate.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
