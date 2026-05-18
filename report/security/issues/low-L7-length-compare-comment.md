# Low · L-7 · Length pre-check before `timingSafeEqual` lacks an explanatory comment

- **Status:** Open
- **Severity:** Low
- **CWE:** n/a
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/middleware/auth.ts:329`

## Summary

Length pre-check is correct (`timingSafeEqual` requires equal-length
buffers) but a future reader might "fix" it as a timing leak and break
the call.

## Impact

Hygiene only.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Add a one-line comment.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
