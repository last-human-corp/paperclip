# Medium · M-1 · AES-GCM auth-tag length not enforced on decrypt

- **Status:** Open · **Demonstrated**
- **Severity:** Medium
- **CWE:** CWE-310
- **Found by:** Semgrep (`gcm-no-tag-length`)
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/secrets/local-encrypted-provider.ts:208-215`

## Summary

`createDecipheriv("aes-256-gcm", masterKey, iv)` then
`decipher.setAuthTag(tag)` accepts any tag length ≥ 4 bytes.

## Impact

A truncated tag (e.g. 4 bytes) dramatically increases forgery probability
(brute-force from 2^128 to 2^32). Matters where an attacker can write the
stored material.

## Reproduction

### Result: **Demonstrated**

Standalone PoC mirrors `decryptValue()` and decrypts ciphertext using a **4-byte** auth tag instead
of the canonical 16-byte tag:

```
[M-1] full 16-byte tag decrypts: super secret value
[M-1] truncated 4-byte tag decrypts: super secret value
```

`createDecipheriv("aes-256-gcm", key, iv)` defaults to accepting any tag length ≥ 4 bytes.
A 4-byte tag drops forgery resistance from 2^128 to 2^32 — within reach of an online oracle.

**Reproducer:** `/tmp/pentest/poc-m1-gcm-tag-length.mjs`

## Fix

Pass `{ authTagLength: 16 }` to `createDecipheriv` **and** validate
`tag.length === 16` before `setAuthTag`.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
