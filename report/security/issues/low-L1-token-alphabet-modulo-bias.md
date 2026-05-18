# Low · L-1 · Invite-token alphabet modulo bias

- **Status:** Open · **Measured**
- **Severity:** Low
- **CWE:** CWE-330
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/routes/access.ts:101-106`

## Summary

`bytes[idx] % INVITE_TOKEN_ALPHABET.length` (36 chars) introduces a small
modulo bias.

## Impact

Marginal; effective entropy drops by ~0.1 bits per character.

## Reproduction

### Result: **Measured**

5,000,000-sample distribution of `bytes[i] % 36`:

```
b: count=156,603, delta=+12.754 %
d: count=156,587, delta=+12.743 %
a: count=155,955, delta=+12.288 %
c: count=155,901, delta=+12.249 %
l: count=135,818, delta=-2.211 %
```

The first four characters (256 mod 36 = 4) are mapped from 8 byte values each, the remaining 32 from
7 each. Effective entropy of the 8-character suffix is ~40.9 bits instead of the theoretical 41.4.

**Reproducer:** `/tmp/pentest/poc-l1-fixed.mjs`

## Fix

Rejection sampling or use a longer byte buffer.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
