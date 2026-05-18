# High · H-5 · CSRF protection scope gaps + cookie Secure flag drop

- **Status:** Open · **Partially confirmed**
- **Severity:** High
- **CWE:** CWE-352, CWE-614
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/middleware/board-mutation-guard.ts:38-87`
  - `server/src/auth/better-auth.ts:103`

## Summary

Mutation guard relies on `Origin`/`Referer` matching. `board_key` and
`local_implicit` actor sources skip CSRF entirely. Cookie `Secure` flag is
dropped whenever `PAPERCLIP_PUBLIC_URL` starts with `http://` — including
Tailnet / VPN / LAN deploys.

## Impact

Browser-loaded session cookies can be replayed in cleartext across any
network that touches the deployment, and cross-origin requests on board
sessions are not CSRF-protected.

## Reproduction

### Result: **Mixed — local_implicit bypass confirmed; browser CSRF blocked by CORS**

1. **Loopback grants implicit board admin without auth.**
   ```bash
   curl http://localhost:3100/api/auth/get-session
   # → {"session":{"id":"paperclip:local_implicit:local-board","userId":"local-board"},"user":{"id":"local-board",…}}
   ```
2. **The mutation guard skips `local_implicit` actors.** A `curl -X POST` from any `Origin:` header
   created a company:
   ```bash
   curl -X POST http://localhost:3100/api/companies -H 'Origin: http://evil.example.com' \
        -H 'content-type: application/json' -d '{"name":"csrf-test"}'
   # → 201 Created
   ```
3. **CORS preflight blocks the typical browser CSRF** — the server emits no `Access-Control-Allow-Origin`,
   so the JSON POST from a real browser preflight fails. `text/plain` / `x-www-form-urlencoded` bodies
   fail because `express.json()` won't parse them.

So the **classical web-attacker** vector is mitigated. The unmitigated risk is:
co-resident attackers (browser extensions, electron apps, malicious local npm postinstall scripts,
trusted-origin XSS) — anything that can dispatch a properly-formed POST to 127.0.0.1:3100.

When combined with C-1 (forged JWT) the local-implicit bypass also lets an attacker authenticate as
an arbitrary agent without setting any `Origin:` header.

**Pen-test log:** `report/security/pentest/2026-05-18-pentest-notes.md` §H-5

## Fix

1. Restrict `disableSecureCookies` to `localhost` / `127.0.0.1` / `::1`.
2. Explicitly set `SameSite=Strict` and `HttpOnly=true` in Better-Auth
   advanced options.
3. Document that board API keys must be server-to-server only.
4. Add a defence-in-depth CSRF token (double-submit) for SPA mutations.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
