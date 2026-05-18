# High · H-4 · ZodError details returned to client (schema disclosure)

- **Status:** Open · **Confirmed live**
- **Severity:** High
- **CWE:** CWE-209
- **Found by:** Manual review
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/middleware/error-handler.ts:59-62`
  - `server/src/middleware/validate.ts:4-8`

## Summary

Validation errors return the raw Zod `.errors` array including paths,
codes, expected types, and discriminator hints.

## Impact

Accelerates API fuzzing, IDOR / role-bypass discovery, and reveals hidden
fields meant for internal use.

## Reproduction

### Result: **Confirmed live**

```bash
curl -i -X PATCH http://localhost:3100/api/auth/profile \
     -H 'content-type: application/json' \
     -d '{"name":123,"weirdField":"x"}'
```

Returns 400 with the full Zod error array to an **unauthenticated** caller:

```json
{"error":"Validation error",
 "details":[{"code":"invalid_type","expected":"string","received":"number",
             "path":["name"],"message":"Expected string, received number"}]}
```

Even more disclosive: a bad role on `POST /api/companies/<id>/agents` leaks the **complete enum**:

```json
{"received":"test","code":"invalid_enum_value",
 "options":["ceo","cto","cmo","cfo","security","engineer","designer","pm","qa","devops","researcher","general"],
 "path":["role"],"message":"…"}
```

Validation runs **before** auth, so any unauthenticated caller can enumerate field names, valid enums,
and discriminator-union types of every Zod schema in the codebase.

**Pen-test log:** `report/security/pentest/2026-05-18-pentest-notes.md` §H-4

## Fix

Return `{ error: "Validation error", fields: paths }` only. Keep full
detail in server logs.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
