# Medium · M-10 · `workflow_dispatch` accepts arbitrary ref input

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-284
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `.github/workflows/release.yml:8-22`

## Summary

`inputs.source_ref` accepts any branch/tag/SHA. No whitelist before the
publish steps execute.

## Impact

Maintainer (or token holder) can dispatch and publish from any branch,
bypassing the master gate.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Validate `source_ref` matches `refs/heads/master` or `v*` tag before
any publish step.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
