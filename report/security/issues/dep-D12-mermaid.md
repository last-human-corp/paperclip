# MODERATE · D12 · Bump `mermaid` to ≥ 11.15.0

- **Status:** Open
- **Severity:** MODERATE
- **Package:** `mermaid`
- **Current:** 11.12.3
- **Fix to:** ≥ 11.15.0
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-6m6c-36f7-fhxh Gantt-chart infinite loop DoS
- GHSA-87f9-hvmw-gh4p Config CSS injection
- GHSA-ghcm-xqfw-q4vr State-diagram HTML injection
- GHSA-xcj9-5m2h-648r `classDefs` CSS injection

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: mermaid" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up mermaid@'^11.15.0' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
