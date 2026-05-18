# Medium · M-7 · `ANTHROPIC_API_KEY` exposed at job-level env

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-200
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `.github/workflows/e2e.yml:17`

## Summary

`env.ANTHROPIC_API_KEY` declared at the job level is visible to every
step, including third-party actions.

## Impact

Any compromised step (action update, dep, etc.) can exfiltrate the key.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Move `env:` block down to the specific step that needs it.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
