# MODERATE · D14 · Bump `better-auth` to ≥ 1.6.2

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `better-auth`
- **Current:** 1.4.18
- **Fix to:** ≥ 1.6.2
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-wxw3-q3m9-c3jr OAuth callback accepts mismatched state when cookie-backed state is used without PKCE

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: better-auth" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up better-auth@'^1.6.2' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
