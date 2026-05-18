# HIGH · D8 · Bump `picomatch` to ≥ 4.0.4

- **Status:** Open
- **Severity:** HIGH
- **Package:** `picomatch`
- **Current:** 4.0.3
- **Fix to:** ≥ 4.0.4
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-c2c7-rcm5-vvqj ReDoS via extglob quantifiers
- GHSA-3v7f-55p6-f55p Method injection in POSIX classes

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: picomatch" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up picomatch@'^4.0.4' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
