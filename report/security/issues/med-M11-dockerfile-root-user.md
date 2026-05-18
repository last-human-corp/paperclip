# Medium · M-11 · Containers run as root + untrusted-review container is unhardened

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-250, CWE-1021
- **Found by:** Trivy + Semgrep
- **Detected:** 2026-05-18
- **Location(s):**
  - `Dockerfile:85`
  - `docker/openclaw-smoke/Dockerfile:8`
  - `docker/Dockerfile.onboard-smoke`
  - `docker/untrusted-review/Dockerfile`
  - `packages/plugins/sandbox-providers/cloudflare/bridge-template/Dockerfile`

## Summary

No final `USER` directive. `docker/untrusted-review/Dockerfile` runs
untrusted PR code with no `--security-opt=no-new-privileges`, no read-only
root, no dropped caps, no seccomp.

## Impact

Container escape → host compromise. For `untrusted-review` this is the
entire purpose of isolation.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Add a non-root `USER` near the end of every Dockerfile. For
`untrusted-review`: `--security-opt=no-new-privileges`, read-only `/`,
`--cap-drop=ALL`, mount only `/work`, restrict egress.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
