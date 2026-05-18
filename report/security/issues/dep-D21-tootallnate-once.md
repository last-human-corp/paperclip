# LOW · D21 · Bump `@tootallnate/once` to ≥ 3.0.1

- **Status:** Open
- **Severity:** LOW
- **Package:** `@tootallnate/once`
- **Current:** 1.1.2
- **Fix to:** ≥ 3.0.1
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-vpq2-c234-7xj6 Incorrect control flow scoping

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: @tootallnate/once" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up @tootallnate/once@'^3.0.1' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
