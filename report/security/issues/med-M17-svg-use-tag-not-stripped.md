# Medium · M-17 · SVG sanitiser does not strip `<use xlink:href="…">` references

- **Status:** Open
- **Severity:** Medium
- **CWE:** CWE-611, CWE-918
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/routes/assets.ts:40-83`

## Summary

DOMPurify config forbids `<script>`/`<foreignObject>` but `<use>` with
`href`/`xlink:href` can reference external resources or data: URLs.

## Impact

SVG XSS / SSRF via `<use>` if DOMPurify normalisation differs from
browser parsing.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Walk the resulting DOM and strip `<use>` elements with non-fragment
hrefs; or forbid `<use>` entirely.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
