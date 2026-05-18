# Low · L-6 · Example secret-shape string in docs trips gitleaks

- **Status:** Open
- **Severity:** Low
- **CWE:** n/a
- **Found by:** Gitleaks
- **Detected:** 2026-05-18
- **Location(s):**
  - `docs/deploy/secrets.md:394`

## Summary

Example JSON in deploy guide contains a string the heuristic flags.

## Impact

Noise.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Replace example value with an obvious placeholder.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
