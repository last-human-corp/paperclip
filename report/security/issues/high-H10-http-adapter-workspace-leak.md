# High · H-10 · HTTP-adapter POST body leaks workspace paths and lease IDs

- **Status:** Open · **Confirmed live**
- **Severity:** High
- **CWE:** CWE-200
- **Found by:** Pen test (chained while reproducing H-1)
- **Detected:** 2026-05-18
- **Location(s):**
  - `server/src/adapters/http/execute.ts:13`
  - `server/src/adapters/http/execute.ts:25`

## Summary

The HTTP adapter constructs every request body as
`{ ...payloadTemplate, agentId, runId, context }` and unconditionally sends it
to the configured URL. The `context` object is the same wake-up context the
heartbeat scheduler hands the adapter — it contains the full
`paperclipEnvironment` block, absolute workspace paths
(`/root/.paperclip/instances/default/workspaces/<agentId>`), lease IDs,
environment driver names, and the wake reason.

## Impact

Any attacker who can register or modify an HTTP-adapter agent points the
`config.url` at their own server and harvests this telemetry every heartbeat
tick. The leak is **passive** — no error response or auth bypass is needed,
the data is sent in the normal request body. Combined with H-1, the same
adapter is also the SSRF primitive, so the attacker simultaneously enumerates
internal HTTP services and exfiltrates Paperclip's internal state.

## Reproduction

### Result: **Confirmed live**

The sink trace captured during the H-1 reproduction shows the body sent by
Paperclip to `http://127.0.0.1:4444/internal-from-paperclip`:

```json
{
  "agentId": "58febd1d-30c4-45d9-a12c-50b596842120",
  "runId":   "0e56f8e8-a8c8-4b26-a0be-4a653d74196f",
  "context": {
    "actorId": "local-board",
    "wakeReason": "pentest",
    "paperclipEnvironment": {
      "id": "d40a3f8f-…",
      "leaseId": "cffe4363-…",
      "workspaceRealization": {
        "local": {
          "path": "/root/.paperclip/instances/default/workspaces/58febd1d-…",
          "source": "agent_home",
          "strategy": "project_primary"
        },
        "rebuild": {
          "localPath": "/root/.paperclip/instances/default/workspaces/58febd1d-…",
          "metadata": { "source": { "kind": "agent_home", … } }
        }
      }
    },
    "paperclipWorkspace": { … },
    "agentHome": "/root/.paperclip/instances/default/workspaces/58febd1d-…"
  }
}
```

Full payload at `report/security/pentest/ssrf-capture.log`.

## Fix

1. Restrict the request body to fields the *adapter* actually needs
   (`agentId`, `runId`, plus an explicit allow-list inside
   `payloadTemplate`). Don't forward the wakeup context unless the adapter
   author opts in.
2. Sanitise filesystem paths out of the `context` (or rewrite them to
   relative paths) before any outbound transmission.
3. Apply the same outbound URL-guard as H-1 so this leak isn't trivially
   reachable from agent / plugin config.

## References

- Umbrella scan report: `report/security/2026-05-18-security-scan.md` §H-1
- Pen-test notes: `report/security/pentest/2026-05-18-pentest-notes.md` §H-1
- Captured payload: `report/security/pentest/ssrf-capture.log`
