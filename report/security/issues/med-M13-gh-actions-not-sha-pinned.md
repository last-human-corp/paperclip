# Medium · M-13 · Third-party GitHub Actions referenced by major-version tag

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-829
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `.github/workflows/*.yml`

## Summary

`docker/build-push-action@v6`, `docker/setup-buildx-action@v3` etc. follow
major tags that can be re-pointed by maintainers or attackers with write
access.

## Impact

Compromised third-party action runs in CI with whatever job-level secrets
are exposed.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Pin to commit SHAs; let Renovate update them.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
