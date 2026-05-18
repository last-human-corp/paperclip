# Low · L-4 · `.dockerignore` does not exclude env / IDE / git

- **Status:** Open
- **Severity:** Low
- **CWE:** CWE-200
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `.dockerignore`

## Summary

Missing `*.env*`, `.npmrc.local`, `Dockerfile*`, `.github`, `.vscode`,
`.idea`.

## Impact

Risk of secrets / dev metadata sneaking into the image.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Append entries to `.dockerignore`.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
