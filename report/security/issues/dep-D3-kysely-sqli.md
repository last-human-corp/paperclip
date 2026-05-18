# HIGH · D3 · Bump `kysely` to ≥ 0.28.17

- **Status:** Open
- **Severity:** HIGH
- **Package:** `kysely`
- **Current:** 0.28.11
- **Fix to:** ≥ 0.28.17
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-8cpq-38p9-67gx MySQL SQLi via insufficient backslash escaping in `sql.lit`
- GHSA-pv5w-4p9q-p3v2 JSON-path traversal injection in `JSONPathBuilder.key()`
- GHSA-wmrf-hv6w-mr66 SQLi via unsanitised JSON path keys

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: kysely" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up kysely@'^0.28.17' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
