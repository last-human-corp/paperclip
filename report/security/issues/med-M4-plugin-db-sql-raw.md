# Medium · M-4 · Plugin DB namespace name interpolated into `sql.raw`

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-89
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/services/plugin-database.ts:305`
  - `server/src/services/plugin-database.ts:376`

## Summary

`CREATE SCHEMA IF NOT EXISTS ${quoteIdentifier(namespaceName)}` via
`sql.raw`. Today protected by an `assertIdentifier` regex.

## Impact

Safe in isolation but fragile. A future refactor weakening the regex or
adding a new caller bypasses parameterisation.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Remove the `sql.raw` short-circuit; always go through the builder; add a
regression test asserting `assertIdentifier("evil; DROP --")` throws.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
