# High · H-8 · `private-hostname-guard` does not resolve DNS or normalise IPs

- **Status:** Open · **Demonstrated**
- **Severity:** High
- **CWE:** CWE-918
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/middleware/private-hostname-guard.ts:3-19`

## Summary

Only inspects the Host/X-Forwarded-Host strings; doesn't resolve DNS,
doesn't normalise IPv6, doesn't reject numeric/decimal/octal/hex IP
encodings of loopback.

## Impact

A controlled DNS record that initially resolves to a public IP can flip
to `127.0.0.1` between the connection check and the actual upstream fetch,
bypassing the guard.

## Reproduction

### Result: **Demonstrated**

```
new URL("http://2130706433/").hostname   → "127.0.0.1"
new URL("http://0x7f000001/").hostname   → "127.0.0.1"
```

The URL constructor normalises decimal/hex IPs, so a static deny-list of *parsed* hostnames is
robust against these forms. The real gaps are:

- The guard inspects the **inbound** Host header only. The outbound `fetch(config.url, …)` call
  in `server/src/adapters/http/execute.ts:19` (H-1) is not protected at all.
- The guard never resolves DNS. A future application of the guard to outbound fetches would still
  miss DNS-rebinding: a name that resolves to `127.0.0.1` at fetch time passes the hostname check.

**Standalone reproducer:** `/tmp/pentest/poc-h8-dns-rebinding.mjs`

## Fix

Pre-resolve hostnames at request time; reject any resolved IP in private
ranges (RFC1918, loopback, link-local, multicast, ULA, IPv4-mapped);
normalise IPs through `net.isIP` and reject non-canonical forms.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
