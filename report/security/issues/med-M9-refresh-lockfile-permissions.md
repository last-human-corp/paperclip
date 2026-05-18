# Medium · M-9 · `refresh-lockfile.yml` permissions too broad

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-732
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `.github/workflows/refresh-lockfile.yml:17-19`

## Summary

`permissions: { contents: write, pull-requests: write }` allows the bot to
force-push and self-approve.

## Impact

Bot can bypass branch protection if not also enforced server-side.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Reduce to `pull-requests: write` only; rely on branch-protection rules
for the merge step.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
