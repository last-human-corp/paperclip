# Medium · M-2 · MD5 used for plugin-UI ETag

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-327
- **Found by:** Manual review (re-confirmed via grep)
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/routes/plugin-ui-static.ts:172`

## Summary

`createHash("md5")` used to compute ETag for plugin static assets.

## Impact

MD5 collisions are trivial; could be abused for cache poisoning if a code
path ever lets an attacker influence bytes hashed into the ETag.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Switch to `createHash("sha256").update(...).digest("hex").slice(0, 16)`.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
