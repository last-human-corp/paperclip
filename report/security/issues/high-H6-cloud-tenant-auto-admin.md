# High · H-6 · Cloud-tenant header auto-grants admin without email verification

- **Status:** Open
- **Severity:** High
- **CWE:** CWE-269, CWE-307
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/middleware/auth.ts:218-249`
  - `server/src/middleware/auth.ts:326-330`

## Summary

Valid `x-paperclip-cloud-tenant-server-token` causes:
- Auto-creation of an auth user with `emailVerified: true` (no verification).
- Owner membership in **all** companies via `onConflictDoNothing`.
- Token comparison is timing-safe but un-rate-limited.

## Impact

If the cloud-tenant token leaks, the attacker gets universal admin on
every company. Brute force is bandwidth-bound only.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Require actual email-verification before granting admin; map stack role
(`owner`/`member`/`support`) to specific permissions instead of universal
admin; add per-IP rate limit + back-off + alerting on failed validations.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
