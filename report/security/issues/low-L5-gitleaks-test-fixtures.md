# Low · L-5 · Test-fixture secrets trigger gitleaks (false positives)

- **Status:** Open
- **Severity:** Low
- **CWE:** n/a
- **Found by:** Gitleaks
- **Detected:** 2026-05-18
- **Location(s):**
  - `packages/plugins/sandbox-providers/exe-dev/src/plugin.test.ts:229`
  - `server/src/__tests__/heartbeat-active-run-output-watchdog.test.ts:221-222`
  - `server/src/__tests__/redaction.test.ts:68-69`

## Summary

Synthetic JWT/PAT/RSA-key fixtures trip gitleaks rules.

## Impact

Noise; blocks adoption of gitleaks as a CI gate.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Add inline `// gitleaks:allow` pragmas or move fixtures behind a
`.gitleaksignore` pattern.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
