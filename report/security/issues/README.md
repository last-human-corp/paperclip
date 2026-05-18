# Security issue tracker

One markdown file per finding from the security scan & pen test. Files use a
canonical structure so they can be triaged, assigned, and closed individually
(or imported wholesale into an issue tracker).

## Filename convention

```
<sev>-<id>-<slug>.md
```

| Severity prefix | Meaning |
|---|---|
| `crit` | Critical — exploitable in default deploy without prerequisites |
| `high` | High — exploitable with realistic prerequisites |
| `med`  | Medium — partial-impact, needs chained pre-conditions |
| `low`  | Low — hygiene / defence-in-depth |
| `dep`  | Dependency vulnerability (rolled into per-package bumps) |

## File template

```
# <severity> <id> · <one-line title>

- **Status:** Open
- **Severity:** Critical / High / Medium / Low
- **CWE:** CWE-NNN
- **Found by:** SAST / SCA / Manual / Pen test
- **Detected:** YYYY-MM-DD
- **Location(s):** path:line

## Summary
…

## Impact
…

## Reproduction
…

## Proof-of-concept
```bash
…
```

## Fix
…

## References
…
```

See `../2026-05-18-security-scan.md` for the umbrella report and `../pentest/`
for the dynamic-testing run notes.
