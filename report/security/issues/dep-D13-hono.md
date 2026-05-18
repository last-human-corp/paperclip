# MODERATE · D13 · Bump `hono` to ≥ 4.12.18

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `hono`
- **Current:** 4.12.12
- **Fix to:** ≥ 4.12.18
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-9vqf-7f2p-gf9v bodyLimit bypass on chunked requests
- GHSA-69xw-7hcm-h432 Unvalidated JSX tag names
- GHSA-458j-xx4x-4375 JSX attribute-name injection
- GHSA-qp7p-654g-cw7p CSS declaration injection in JSX SSR
- GHSA-p77w-8qqv-26rm Cache middleware ignores Vary headers
- GHSA-hm8q-7f3q-5f36 Improper validation of JWT NumericDate claims

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: hono" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up hono@'^4.12.18' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
