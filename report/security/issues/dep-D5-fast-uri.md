# HIGH · D5 · Bump `fast-uri` to ≥ 3.1.2

- **Status:** Open
- **Severity:** HIGH
- **Package:** `fast-uri`
- **Current:** 3.1.0
- **Fix to:** ≥ 3.1.2
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-q3j6-qgpj-74h6 Path traversal via percent-encoded dot segments
- GHSA-v39h-62p7-jpjc Host confusion via percent-encoded authority delimiters

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: fast-uri" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up fast-uri@'^3.1.2' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
