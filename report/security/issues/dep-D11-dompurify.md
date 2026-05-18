# MODERATE · D11 · Bump `dompurify` to ≥ 3.4.0

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `dompurify`
- **Current:** 3.3.2
- **Fix to:** ≥ 3.4.0
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-39q2-94rc-95cp `ADD_TAGS` function form bypasses `FORBID_TAGS`
- GHSA-v9jr-rg53-9pgp Prototype pollution → XSS bypass
- GHSA-crv5-9vww-q3g8 `SAFE_FOR_TEMPLATES` bypass in `RETURN_DOM` mode
- GHSA-h7mw-gpvr-xq4m `FORBID_TAGS` bypassed by function-based `ADD_TAGS`

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: dompurify" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up dompurify@'^3.4.0' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
