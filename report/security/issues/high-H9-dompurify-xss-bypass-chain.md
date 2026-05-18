# High · H-9 · SVG asset sanitiser uses DOMPurify 3.3.2 (known XSS bypasses)

- **Status:** Open · **Static-only — defence-in-depth blocked all 7 live payloads**
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

### Result: **Live exploitation blocked by defence-in-depth**

Seven SVG XSS payloads were uploaded via `POST /api/companies/<id>/assets/images`:

| Payload | Result |
|---|---|
| `<svg onload="alert(1)">` | stripped to `<svg width="10" height="10"><rect …/></svg>` |
| `<svg><script>alert(1)</script></svg>` | `<script>` removed |
| `<svg><foreignObject>…</foreignObject></svg>` | `<foreignObject>` removed |
| `<svg><use xlink:href="http://evil/poison.svg#g"/></svg>` | external `xlink:href` stripped |
| `<svg><a><animate attributeName="xlink:href" values="javascript:…"/></a></svg>` | `<animate>` removed |
| CDATA-wrapped `<script>` | content escaped to entities |
| Root-level `onload="alert(1)"` (with XML decl) | `onload` stripped |

`server/src/routes/assets.ts:21-83` applies DOMPurify **and** a hand-rolled
second pass that walks the DOM and removes `on*` and external `href`/`xlink:href`
attributes. The DOMPurify 3.3.2 advisories (function-form `ADD_TAGS` bypass,
`SAFE_FOR_TEMPLATES` bypass, prototype pollution → XSS) all require config
patterns that this sanitiser does not use.

**Revised severity:** the **upgrade to ≥ 3.4.0 is still warranted** (hygiene +
defence-in-depth for future config drift), but live impact is currently **Low**,
not High. The umbrella report's High rating was based on the pinned-version
advisory alone and should be adjusted.

**Test payloads:** `/tmp/pentest/svg/p{1..7}-*.svg` (not persisted to repo).

## Fix

Bump DOMPurify to ≥ 3.4.0 and add unit tests for the bypass payloads.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
