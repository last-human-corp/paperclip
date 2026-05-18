# HIGH · D9 · Bump `lodash-es` to ≥ 4.18.0

- **Status:** Open
- **Severity:** HIGH
- **Package:** `lodash-es`
- **Current:** 4.17.23
- **Fix to:** ≥ 4.18.0
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-r5fr-rjxr-66jc Code injection via `_.template` imports key names
- GHSA-f23m-r3pf-42rh Prototype pollution in `_.unset`/`_.omit`

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: lodash-es" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up lodash-es@'^4.18.0' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
