# High · H-1 · Outbound SSRF in HTTP adapter — no private-IP/DNS guard

- **Status:** Open · **Confirmed live (prerequisite)**
- **Severity:** High
- **CWE:** CWE-918
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/adapters/http/execute.ts:19`

## Summary

The HTTP adapter calls `await fetch(url, ...)` where `url` comes straight
from adapter config (`asString(config.url, "")`). No allow-list, no DNS
resolution check, no private-IP block, no port filter, no scheme filter.

## Impact

Anyone able to author an HTTP adapter (today: company admins; future:
plugins) can pivot the Paperclip server into the internal network:
- `http://169.254.169.254/latest/meta-data/iam/security-credentials/` →
  cloud IAM credentials.
- `http://127.0.0.1:5432` → Postgres unix port, redis, k8s API.
- `http://[::1]:3100/admin/...` → reach loopback-only admin endpoints.

`private-hostname-guard` middleware exists but only protects **inbound**
requests *to* Paperclip, not **outbound** ones *from* Paperclip.

## Reproduction

### Result: **Confirmed live (prerequisite stored)**

An admin (or anyone with implicit-board access — see C-1 / H-5) can register an HTTP-adapter agent
whose URL points at any internal endpoint. The server **stores and accepts the URL with no validation**:

```bash
curl -X POST http://localhost:3100/api/companies/<id>/agents -H 'content-type: application/json' -d '{
  "name": "SSRF Probe",
  "role": "engineer",
  "adapterType": "http",
  "adapterConfig": {
    "url": "http://169.254.169.254/latest/meta-data/",
    "method": "GET",
    "timeoutMs": 3000
  }
}'
# → 201 Created  (agent stored with malicious URL)
```

The next heartbeat tick will issue a `fetch("http://169.254.169.254/latest/meta-data/")` from the
Paperclip process. In any cloud deploy this lifts IMDS credentials. The
`server/src/adapters/http/execute.ts:19` `fetch(config.url, …)` call has zero URL validation
(no allow-list, no DNS check, no private-IP filter, no scheme filter, no port filter).

The Zod schema rejected my first probe (`role: "test"`) — that is **not** a security control,
it just enforces the role enum. Using a valid role got the malicious URL persisted.

**Pen-test log:** `report/security/pentest/2026-05-18-pentest-notes.md` §H-1

## Fix

1. Factor out an `assertPublicUrl(url)` helper that:
   - Rejects schemes other than http/https.
   - DNS-resolves the host and rejects RFC1918, loopback, link-local,
     multicast, ULA, IPv4-mapped, and 169.254.0.0/16.
   - Rejects non-canonical IP forms (decimal, octal, hex).
   - Re-checks the resolved IP at the time of the fetch (defeats DNS
     rebinding).
2. Call the helper from every place that fetches a config-supplied URL —
   currently `server/src/adapters/http/execute.ts:19`, future-proof for
   webhook executors and plugin proxy URLs.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
