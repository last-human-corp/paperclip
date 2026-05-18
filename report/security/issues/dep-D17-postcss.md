# MODERATE · D17 · Bump `postcss` to ≥ 8.5.10

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `postcss`
- **Current:** 8.5.6
- **Fix to:** ≥ 8.5.10
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-qx2v-qp2m-jg93 XSS via unescaped `</style>`

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: postcss" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up postcss@'^8.5.10' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
