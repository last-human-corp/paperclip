# Medium · M-3 · `Secure` cookie flag dropped whenever public URL is `http://`

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-614
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/auth/better-auth.ts:103,123`

## Summary

`const isHttpOnly = publicUrl ? publicUrl.startsWith("http://") : false;`
then `disableSecureCookies: isHttpOnly`.

## Impact

Any LAN / Tailnet / VPN deploy with `PAPERCLIP_PUBLIC_URL=http://...` ships
session cookies without `Secure`, allowing MITM cookie theft.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Allow-list loopback hostnames only (`localhost`, `127.0.0.1`, `[::1]`).

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
