# HIGH · D10 · Bump `defu` to ≥ 6.1.5

- **Status:** Open
- **Severity:** HIGH
- **Package:** `defu`
- **Current:** 6.1.4
- **Fix to:** ≥ 6.1.5
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-737v-mqg7-c878 Prototype pollution via `__proto__` key

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: defu" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up defu@'^6.1.5' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
