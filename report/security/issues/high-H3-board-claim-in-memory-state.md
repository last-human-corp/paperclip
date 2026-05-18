# High · H-3 · Board-claim challenge stored in process memory only

- **Status:** Open
- **Severity:** High
- **CWE:** CWE-613
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/board-claim.ts:21,34-41,63-65,143-146`

## Summary

Bootstrap claim flow keeps the challenge in a module-level
`activeChallenge` variable. State is lost on restart and not shared across
replicas.

## Impact

- Restarts drop in-flight claims silently (UX bug, locks out admins).
- Multi-replica deployments break: each replica has its own challenge,
  causing TOCTOU races where the same code could be redeemed twice.
- No per-IP rate limit on the bootstrap endpoint, so a short claim code
  can be brute-forced.

## Reproduction

_To be filled by pen test_ — see `../pentest/2026-05-18-pentest-notes.md` for the
working notes that produced (or attempted) a PoC for this finding.

## Fix

Persist challenge state to DB with `claimed_at` column and an idempotency
key; add rate-limit + lockout after N failed attempts.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
