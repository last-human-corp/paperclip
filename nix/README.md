# Nix packaging

First-class Nix support for Paperclip. See [`doc/NIX.md`](../doc/NIX.md)
for the full how-to.

## Quick reference

```sh
# Build the server from source
nix build .#paperclip

# Run it in a scratch state dir
PAPERCLIP_HOME=$(mktemp -d) DATABASE_URL=… nix run .#paperclip

# Drop into a dev shell with Node 20, pnpm 9, and every runtime binary
nix develop

# Run the NixOS VM test
nix flake check
```

## Files

| Path | Purpose |
|------|---------|
| `../flake.nix` | Flake entry; exposes packages, devShells, nixosModules, checks |
| `package.nix` | `pkgs.paperclip` — source-built derivation of the pnpm workspace |
| `agent-clis.nix` | `pkgs.paperclip-agent-clis` — bundle of claude-code/codex/opencode |
| `dev-shell.nix` | `nix develop` shell with all runtime deps |
| `module.nix` | `nixosModules.paperclip` — systemd service + Postgres wiring |
| `tests/basic.nix` | `nixosTest` that boots the module and probes `/api/health` |

## Updating hashes

The package and the agent CLIs declare `lib.fakeHash` for their fixed-output
fetches on first add. Build once and replace each printed mismatch with the
hash from the failure message. Re-run after any `pnpm-lock.yaml` change.
