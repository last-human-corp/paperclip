# Medium · M-6 · `sql.unsafe()` predicate helper in backup tooling

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-89
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `packages/db/src/backup-lib.ts:567`
  - `packages/db/src/backup-lib.ts:580`
  - `packages/db/src/backup-lib.ts:606`
  - `packages/db/src/backup-lib.ts:778`
  - `packages/db/src/backup-lib.ts:815`
  - `packages/db/src/backup-lib.ts:834`

## Summary

`nonSystemSchemaPredicate(identifier)` builds a SQL fragment from
`identifier` and injects it via `sql.unsafe`. Callers currently pass
hardcoded strings, but the API does not enforce that.

## Impact

Future callers passing untrusted identifiers introduce SQL injection.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Type `identifier` as a closed enum of known column names; add a lint
rule banning new `sql.unsafe()` usages outside this file.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
