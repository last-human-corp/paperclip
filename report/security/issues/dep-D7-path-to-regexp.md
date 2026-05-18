# HIGH · D7 · Bump `path-to-regexp` to ≥ 8.4.0

- **Status:** Open
- **Severity:** HIGH
- **Package:** `path-to-regexp`
- **Current:** 8.3.0
- **Fix to:** ≥ 8.4.0
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-j3q9-mxjg-w52f DoS via sequential optional groups
- GHSA-27v5-c462-wpq7 ReDoS via multiple wildcards

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: path-to-regexp" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up path-to-regexp@'^8.4.0' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
