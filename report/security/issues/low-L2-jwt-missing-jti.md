# Low · L-2 · Agent JWT has no `jti` claim

- **Status:** Open
- **Severity:** Low
- **CWE:** CWE-613
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/agent-auth-jwt.ts:68-93`

## Summary

`jti` claim is accepted on verify but never produced.

## Impact

Blocks per-token revocation, log correlation, and replay-detection. See
H-7 for the related revocation issue.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Generate `jti: randomUUID()` in `createLocalAgentJwt`.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
