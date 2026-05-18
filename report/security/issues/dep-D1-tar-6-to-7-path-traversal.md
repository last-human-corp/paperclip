# HIGH · D1 · Bump `tar` to ≥ 7.5.11

- **Status:** Open
- **Severity:** HIGH
- **Package:** `tar`
- **Current:** 6.2.1
- **Fix to:** ≥ 7.5.11
- **Found by:** OSV-Scanner + Trivy
- **Detected:** 2026-05-18

## Advisories

- GHSA-34x7-hfp2-rc4v Hardlink path traversal
- GHSA-83g3-92jg-28cx Hardlink target escape via symlink chain
- GHSA-8qq5-rm4j-mr97 Arbitrary file overwrite / symlink poisoning
- GHSA-9ppj-qmqm-q256 Symlink path traversal via drive-relative linkpath
- GHSA-qffp-2rhf-9h96 Hardlink path traversal via drive-relative linkpath
- GHSA-r6q2-hw4h-h46w Race condition in path reservations

## Reproduction

```bash
# Verify vulnerable version in lockfile
grep -A1 "name: tar" pnpm-lock.yaml | head -20
# Or run OSV-Scanner
/tmp/sectools/osv-scanner scan source --recursive .
```

## Fix

```bash
pnpm up tar@'^7.5.11' --recursive
pnpm install --lockfile-only
pnpm test:run
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §3
