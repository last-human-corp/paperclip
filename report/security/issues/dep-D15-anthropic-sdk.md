# MODERATE · D15 · Bump `@anthropic-ai/sdk` to ≥ 0.91.1

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `@anthropic-ai/sdk`
- **Current:** 0.81.0
- **Fix to:** ≥ 0.91.1
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-p7fg-763f-g4gf Insecure default file permissions in memory tool

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: @anthropic-ai/sdk" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up @anthropic-ai/sdk@'^0.91.1' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
