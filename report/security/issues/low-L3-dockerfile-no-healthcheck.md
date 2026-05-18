# Low · L-3 · Dockerfiles missing `HEALTHCHECK`

- **Status:** Open
- **Severity:** Low
- **CWE:** CWE-754
- **Found by:** Trivy (`DS-0026`)
- **Detected:** 2026-05-18
- **Location(s):**
  - `Dockerfile`
  - `docker/*/Dockerfile`

## Summary

No `HEALTHCHECK` directive in any Dockerfile.

## Impact

Operational only — orchestrators can't distinguish a hung process from a
healthy one.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Add `HEALTHCHECK CMD ...` (typically a curl to `/health`).

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
