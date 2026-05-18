# High · H-9 · SVG asset sanitiser uses DOMPurify 3.3.2 (known XSS bypasses)

- **Status:** Open
- **Severity:** High
- **CWE:** CWE-79
- **Found by:** SCA + Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/routes/assets.ts:21-83`
  - `ui/src/components/MarkdownBody.tsx:435-488`

## Summary

DOMPurify 3.3.2 has four open advisories (GHSA-39q2-94rc-95cp,
GHSA-v9jr-rg53-9pgp, GHSA-crv5-9vww-q3g8, GHSA-h7mw-gpvr-xq4m) including
`FORBID_TAGS` bypass via function-form `ADD_TAGS` and prototype-pollution
→ XSS.

## Impact

An attacker who can upload an SVG asset gets stored XSS in the UI.
Mitigated somewhat by the JSDOM rebuild but not eliminated.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Bump DOMPurify to ≥ 3.4.0 and add unit tests for the bypass payloads.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
