# MODERATE · D20 · Bump `brace-expansion` to ≥ 5.0.6

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `brace-expansion`
- **Current:** 5.0.5
- **Fix to:** ≥ 5.0.6
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-jxxr-4gwj-5jf2 Large numeric range defeats DoS protection

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: brace-expansion" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up brace-expansion@'^5.0.6' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
