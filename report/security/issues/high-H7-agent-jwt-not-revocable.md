# High · H-7 · Agent JWTs are not revocable (48 h TTL, no jti)

- **Status:** Open · **Confirmed live (chained with C-1)**
- **Severity:** High
- **CWE:** CWE-613
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/middleware/auth.ts:139-170`
  - `server/src/agent-auth-jwt.ts:68-93`

## Summary

Default TTL is `60 * 60 * 48` seconds and the token has no `jti` claim;
there is no server-side revocation list.

## Impact

Deleted or terminated agents continue to authenticate for up to 48 h.
Compromised JWTs cannot be invalidated short of rotating the signing
secret — which invalidates every other agent simultaneously.

## Reproduction

### Result: **Confirmed (chained)**

This finding is tied to C-1. With the forged token from `/tmp/pentest/poc-c1-jwt-forge.mjs`:

- TTL defaults to 48 h (`server/src/agent-auth-jwt.ts:34`).
- No `jti` claim is generated or stored.
- `verifyLocalAgentJwt` only checks signature + exp; the only late-stage check is "does the agent
  still exist and is it not terminated".

If the agent record is deleted, requests start failing — but only because Postgres returns no row.
There is no revocation table, no nonce list, no jti deny-list, no secret-rotation tracking. To
invalidate a leaked token before its 48 h expiry the operator must rotate `BETTER_AUTH_SECRET`
(or `PAPERCLIP_AGENT_JWT_SECRET`), which simultaneously invalidates **every** agent's token.

**Pen-test log:** `report/security/pentest/2026-05-18-pentest-notes.md` §H-7

## Fix

Add `jti: randomUUID()`; check against an `agent_jwt_revocations` table
on every verify; revoke on agent terminate/delete; lower default TTL to
≤ 1 h with refresh.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
