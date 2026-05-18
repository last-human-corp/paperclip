# Issue index

53 issue files generated from the security scan + manual analysis + pen test.

Status legend: **OPEN** = no fix in tree; **🔥 Confirmed live** = exploited
against a running server during the pen test; **🧪 Demonstrated** = PoC code
mirrors the production code path; **📄 Static-only** = source-grep evidence.

## Critical

| ID | File | Title | Pen-test status |
|---|---|---|---|
| C-1 | [`crit-C1-jwt-secret-reuse-and-weak-default.md`](crit-C1-jwt-secret-reuse-and-weak-default.md) | JWT signing secret reuse and weak `.env.example` default | 🔥 Confirmed live |

## High

| ID | File | Title | Pen-test status |
|---|---|---|---|
| H-1 | [`high-H1-ssrf-http-adapter.md`](high-H1-ssrf-http-adapter.md) | Outbound SSRF in HTTP adapter — no private-IP/DNS guard | 🔥 Confirmed live (full chain) |
| H-2 | [`high-H2-gh-actions-shell-injection.md`](high-H2-gh-actions-shell-injection.md) | GitHub Actions `run:` shell-injection (3 sites) | 📄 Static-only · severity reduced to Medium for these sites |
| H-3 | [`high-H3-board-claim-in-memory-state.md`](high-H3-board-claim-in-memory-state.md) | Board-claim challenge stored in process memory only | 📄 Static-only |
| H-4 | [`high-H4-zoderror-schema-disclosure.md`](high-H4-zoderror-schema-disclosure.md) | ZodError details returned to client (schema disclosure) | 🔥 Confirmed live |
| H-5 | [`high-H5-csrf-scope-gaps.md`](high-H5-csrf-scope-gaps.md) | CSRF protection scope gaps + cookie Secure flag drop | 🔥 Partially confirmed |
| H-6 | [`high-H6-cloud-tenant-auto-admin.md`](high-H6-cloud-tenant-auto-admin.md) | Cloud-tenant header auto-grants admin without email verification | 📄 Static-only |
| H-7 | [`high-H7-agent-jwt-not-revocable.md`](high-H7-agent-jwt-not-revocable.md) | Agent JWTs are not revocable (48 h TTL, no jti) | 🔥 Confirmed live (chained with C-1) |
| H-8 | [`high-H8-dns-rebinding-gap.md`](high-H8-dns-rebinding-gap.md) | `private-hostname-guard` does not resolve DNS or normalise IPs | 🧪 Demonstrated |
| H-9 | [`high-H9-dompurify-xss-bypass-chain.md`](high-H9-dompurify-xss-bypass-chain.md) | SVG asset sanitiser uses DOMPurify 3.3.2 | 📄 Static-only · live exploitation blocked by defence-in-depth |
| H-10 | [`high-H10-http-adapter-workspace-leak.md`](high-H10-http-adapter-workspace-leak.md) | HTTP-adapter POST body leaks workspace paths and lease IDs | 🔥 Confirmed live |

## Medium

| ID | File | Title | Pen-test status |
|---|---|---|---|
| M-1 | [`med-M1-gcm-tag-length-not-validated.md`](med-M1-gcm-tag-length-not-validated.md) | AES-GCM auth-tag length not enforced on decrypt | 🧪 Demonstrated |
| M-2 | [`med-M2-md5-etag.md`](med-M2-md5-etag.md) | MD5 used for plugin-UI ETag | 📄 Source-confirmed |
| M-3 | [`med-M3-secure-cookie-dropped-http.md`](med-M3-secure-cookie-dropped-http.md) | `Secure` cookie flag dropped whenever public URL is `http://` | 📄 Source-confirmed |
| M-4 | [`med-M4-plugin-db-sql-raw.md`](med-M4-plugin-db-sql-raw.md) | Plugin DB namespace name interpolated into `sql.raw` | 📄 Static-only |
| M-5 | [`med-M5-pg-dump-path-env-no-validation.md`](med-M5-pg-dump-path-env-no-validation.md) | `pg_dump`/`psql` paths read from env without validation | 📄 Static-only |
| M-6 | [`med-M6-sql-unsafe-predicate-helper.md`](med-M6-sql-unsafe-predicate-helper.md) | `sql.unsafe()` predicate helper in backup tooling | 📄 Static-only |
| M-7 | [`med-M7-anthropic-key-job-env.md`](med-M7-anthropic-key-job-env.md) | `ANTHROPIC_API_KEY` exposed at job-level env | 📄 Static-only |
| M-8 | [`med-M8-release-smoke-secrets-echoed.md`](med-M8-release-smoke-secrets-echoed.md) | Secrets echoed to GitHub Actions log | 📄 Static-only |
| M-9 | [`med-M9-refresh-lockfile-permissions.md`](med-M9-refresh-lockfile-permissions.md) | `refresh-lockfile.yml` permissions too broad | 📄 Static-only |
| M-10 | [`med-M10-workflow-dispatch-any-ref.md`](med-M10-workflow-dispatch-any-ref.md) | `workflow_dispatch` accepts arbitrary ref input | 📄 Static-only |
| M-11 | [`med-M11-dockerfile-root-user.md`](med-M11-dockerfile-root-user.md) | Containers run as root + untrusted-review unhardened | 📄 Source-confirmed |
| M-12 | [`med-M12-base-image-not-digest-pinned.md`](med-M12-base-image-not-digest-pinned.md) | Container base images use mutable tags | 📄 Static-only |
| M-13 | [`med-M13-gh-actions-not-sha-pinned.md`](med-M13-gh-actions-not-sha-pinned.md) | Third-party GitHub Actions referenced by major-version tag | 📄 Static-only |
| M-17 | [`med-M17-svg-use-tag-not-stripped.md`](med-M17-svg-use-tag-not-stripped.md) | SVG sanitiser does not strip `<use xlink:href="…">` references | 📄 Static-only |

## Low

| ID | File | Title | Pen-test status |
|---|---|---|---|
| L-1 | [`low-L1-token-alphabet-modulo-bias.md`](low-L1-token-alphabet-modulo-bias.md) | Invite-token alphabet modulo bias | 🧪 Measured |
| L-2 | [`low-L2-jwt-missing-jti.md`](low-L2-jwt-missing-jti.md) | Agent JWT has no `jti` claim | 📄 Source-confirmed |
| L-3 | [`low-L3-dockerfile-no-healthcheck.md`](low-L3-dockerfile-no-healthcheck.md) | Dockerfiles missing `HEALTHCHECK` | 📄 Static-only |
| L-4 | [`low-L4-dockerignore-gaps.md`](low-L4-dockerignore-gaps.md) | `.dockerignore` does not exclude env / IDE / git | 📄 Static-only |
| L-5 | [`low-L5-gitleaks-test-fixtures.md`](low-L5-gitleaks-test-fixtures.md) | Test-fixture secrets trigger gitleaks (false positives) | 📄 Static-only |
| L-6 | [`low-L6-docs-example-secret.md`](low-L6-docs-example-secret.md) | Example secret-shape string in docs trips gitleaks | 📄 Static-only |
| L-7 | [`low-L7-length-compare-comment.md`](low-L7-length-compare-comment.md) | Length pre-check before `timingSafeEqual` lacks comment | 📄 Static-only |

## Dependency CVEs (lockfile-confirmed)

| ID | File | Package | Fix to | Severity |
|---|---|---|---|---|
| D-1 | [`dep-D1-tar-6-to-7-path-traversal.md`](dep-D1-tar-6-to-7-path-traversal.md) | `tar` 6.2.1 | ≥ 7.5.11 | HIGH |
| D-2 | [`dep-D2-vite-6-and-7-file-read.md`](dep-D2-vite-6-and-7-file-read.md) | `vite` 6.4.1 / 7.3.1 | 6.4.2 / 7.3.2 | HIGH |
| D-3 | [`dep-D3-kysely-sqli.md`](dep-D3-kysely-sqli.md) | `kysely` 0.28.11 | ≥ 0.28.17 | HIGH |
| D-4 | [`dep-D4-undici-ws-dos.md`](dep-D4-undici-ws-dos.md) | `undici` 5.29.0 | ≥ 6.24.0 | HIGH |
| D-5 | [`dep-D5-fast-uri.md`](dep-D5-fast-uri.md) | `fast-uri` 3.1.0 | ≥ 3.1.2 | HIGH |
| D-6 | [`dep-D6-fast-xml-parser.md`](dep-D6-fast-xml-parser.md) | `fast-xml-parser` 5.3.6 | ≥ 5.5.7 | HIGH |
| D-7 | [`dep-D7-path-to-regexp.md`](dep-D7-path-to-regexp.md) | `path-to-regexp` 8.3.0 | ≥ 8.4.0 | HIGH |
| D-8 | [`dep-D8-picomatch.md`](dep-D8-picomatch.md) | `picomatch` 4.0.3 | ≥ 4.0.4 | HIGH |
| D-9 | [`dep-D9-lodash-es.md`](dep-D9-lodash-es.md) | `lodash-es` 4.17.23 | ≥ 4.18.0 | HIGH |
| D-10 | [`dep-D10-defu.md`](dep-D10-defu.md) | `defu` 6.1.4 | ≥ 6.1.5 | HIGH |
| D-11 | [`dep-D11-dompurify.md`](dep-D11-dompurify.md) | `dompurify` 3.3.2 | ≥ 3.4.0 | MODERATE |
| D-12 | [`dep-D12-mermaid.md`](dep-D12-mermaid.md) | `mermaid` 11.12.3 | ≥ 11.15.0 | MODERATE |
| D-13 | [`dep-D13-hono.md`](dep-D13-hono.md) | `hono` 4.12.12 | ≥ 4.12.18 | MODERATE |
| D-14 | [`dep-D14-better-auth.md`](dep-D14-better-auth.md) | `better-auth` 1.4.18 | ≥ 1.6.2 | MODERATE |
| D-15 | [`dep-D15-anthropic-sdk.md`](dep-D15-anthropic-sdk.md) | `@anthropic-ai/sdk` 0.81.0 | ≥ 0.91.1 | MODERATE |
| D-16 | [`dep-D16-ip-address.md`](dep-D16-ip-address.md) | `ip-address` 10.1.0 | ≥ 10.1.1 | MODERATE |
| D-17 | [`dep-D17-postcss.md`](dep-D17-postcss.md) | `postcss` 8.5.6 | ≥ 8.5.10 | MODERATE |
| D-18 | [`dep-D18-uuid.md`](dep-D18-uuid.md) | `uuid` 11.1.0 | ≥ 11.1.1 | MODERATE |
| D-19 | [`dep-D19-esbuild.md`](dep-D19-esbuild.md) | `esbuild` 0.18.20 | ≥ 0.25.0 | MODERATE |
| D-20 | [`dep-D20-brace-expansion.md`](dep-D20-brace-expansion.md) | `brace-expansion` 5.0.5 | ≥ 5.0.6 | MODERATE |
| D-21 | [`dep-D21-tootallnate-once.md`](dep-D21-tootallnate-once.md) | `@tootallnate/once` 1.1.2 | ≥ 3.0.1 | LOW |

## Source documents

- Umbrella scan & analysis report — [`../2026-05-18-security-scan.md`](../2026-05-18-security-scan.md)
- Pen-test working notes — [`../pentest/2026-05-18-pentest-notes.md`](../pentest/2026-05-18-pentest-notes.md)
- PoC scripts — [`../pentest/poc-*.mjs`](../pentest/)
