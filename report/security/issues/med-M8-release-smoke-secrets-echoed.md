# Medium · M-8 · Secrets echoed to GitHub Actions log in release-smoke workflow

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-532
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `.github/workflows/release-smoke.yml:79-80`

## Summary

`echo "SMOKE_ADMIN_PASSWORD=$SMOKE_ADMIN_PASSWORD"` writes a secret into
the runner log.

## Impact

Anyone with repo read access can recover the credential from logs.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Remove the echo; use `::add-mask::` if a redacted form is needed; gate
behind `RUNNER_DEBUG`.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
