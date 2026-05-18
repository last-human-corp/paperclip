# Medium · M-5 · `pg_dump`/`psql` paths read from env without validation

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-78, CWE-426
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `packages/db/src/backup-lib.ts:292-296`
  - `packages/db/src/backup-lib.ts:323-327`

## Summary

`process.env.PAPERCLIP_PG_DUMP_PATH || "pg_dump"` — falls back to PATH
lookup; relative paths accepted. Connection string passed as `--dbname=...`
argv exposes credentials in `ps`.

## Impact

Compromised env or PATH entry → arbitrary binary execution as Paperclip
user.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Require absolute paths; verify the binary exists and is executable; use
`PGPASSFILE` instead of inlining credentials in argv.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
