# HIGH · D4 · Bump `undici` to ≥ 6.24.0

- **Status:** Open
- **Severity:** HIGH
- **Package:** `undici`
- **Current:** 5.29.0
- **Fix to:** ≥ 6.24.0
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-vrm6-8vpv-qv8q WS unbounded memory consumption
- GHSA-v9p9-hfj2-hcw8 WS unhandled exception
- GHSA-4992-7rv2-5pvq CRLF injection via `upgrade` option
- GHSA-2mjp-6q6p-2qxm Request/response smuggling
- GHSA-g9mf-h72j-4rw9 Unbounded decompression chain

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: undici" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up undici@'^6.24.0' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
