# HIGH · D6 · Bump `fast-xml-parser` to ≥ 5.5.7

- **Status:** Open
- **Severity:** HIGH
- **Package:** `fast-xml-parser`
- **Current:** 5.3.6
- **Fix to:** ≥ 5.5.7
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-8gc5-j5rx-235r Entity expansion bypass
- GHSA-jp2q-39xq-3w4g Falsy-evaluation bypass
- GHSA-gh4j-gqv2-49f6 XML comment / CDATA injection
- GHSA-fj3w-jwp8-x2g3 Stack overflow in XMLBuilder

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: fast-xml-parser" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up fast-xml-parser@'^5.5.7' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
