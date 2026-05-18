# MODERATE · D19 · Bump `esbuild` to ≥ 0.25.0

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `esbuild`
- **Current:** 0.18.20
- **Fix to:** ≥ 0.25.0
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-67mh-4wv8-2f99 Dev server CSRF

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: esbuild" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up esbuild@'^0.25.0' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
