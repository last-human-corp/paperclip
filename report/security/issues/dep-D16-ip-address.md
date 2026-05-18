# MODERATE · D16 · Bump `ip-address` to ≥ 10.1.1

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `ip-address`
- **Current:** 10.1.0
- **Fix to:** ≥ 10.1.1
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-v2v4-37r5-5v8g XSS in Address6 HTML-emitting methods

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: ip-address" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up ip-address@'^10.1.1' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
