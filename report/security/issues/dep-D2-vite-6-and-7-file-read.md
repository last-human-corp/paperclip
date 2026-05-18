# HIGH · D2 · Bump `vite` to 6.4.2 / 7.3.2

- **Status:** Open
- **Severity:** HIGH
- **Package:** `vite`
- **Current:** 6.4.1, 7.3.1
- **Fix to:** 6.4.2 / 7.3.2
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-p9ff-h696-f583 Arbitrary file read via dev-server WebSocket
- GHSA-v2wj-q39q-566r `server.fs.deny` bypassed with queries
- GHSA-4w7w-66w2-5vf9 Path traversal in optimized deps `.map`

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: vite" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up vite@'6.4.2 / 7.3.2' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
