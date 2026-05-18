# MODERATE · D18 · Bump `uuid` to ≥ 11.1.1

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `uuid`
- **Current:** 11.1.0
- **Fix to:** ≥ 11.1.1
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-w5hq-g745-h8pq Missing buffer bounds check

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: uuid" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up uuid@'^11.1.1' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
