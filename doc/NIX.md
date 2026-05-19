# Nix / NixOS

Paperclip ships a flake at the repo root with three things:

1. A source-built derivation: `nix build github:paperclipai/paperclip#paperclip`
2. A NixOS module: `services.paperclip.enable = true;`
3. A dev shell: `nix develop`

All three live in `flake.nix` and `nix/`. Native build sequence mirrors the
Dockerfile; the systemd unit mirrors the env defaults from
`scripts/docker-entrypoint.sh` and `doc/DOCKER.md`.

## Build

```sh
nix build .#paperclip
./result/bin/paperclip --help
```

The wrapper extends PATH with `git`, `gh`, `ripgrep`, `openssh`, `jq`,
`python3`, `tailscale`, `curl`, `wget`, `coreutils`, `bash` — every binary
the server may exec at runtime.

Native modules (`better-sqlite3`, `sharp`) are rebuilt via `pnpm`'s
post-install hooks during `pnpm.configHook`. No prebuilt-binary fetch at
runtime.

### Agent CLIs

The optional `paperclip-agent-clis` derivation bundles `claude` (from
`@anthropic-ai/claude-code`), `codex` (from `@openai/codex`), and
`opencode` (from `opencode-ai`). Each upstream npm package is a thin
dispatcher that downloads a platform-specific binary at install time;
the Nix derivation skips the dispatcher and fetches the matching
`linux-x64` / `linux-arm64` tarball directly. The wrapper PATH from
`services.paperclip` picks them up automatically when
`agentClis.enable = true`.

## Run standalone

```sh
export PAPERCLIP_HOME=$(mktemp -d)
export BETTER_AUTH_SECRET=$(openssl rand -hex 32)
export DATABASE_URL=postgres://you@localhost:5432/paperclip
nix run .#paperclip
```

Open `http://localhost:3100`.

## NixOS service

```nix
{
  inputs.paperclip.url = "github:paperclipai/paperclip";

  outputs = { self, nixpkgs, paperclip }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        paperclip.nixosModules.paperclip
        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            (final: prev: {
              paperclip = paperclip.packages.${pkgs.system}.paperclip;
              paperclip-agent-clis = paperclip.packages.${pkgs.system}.paperclip-agent-clis;
            })
          ];

          services.paperclip = {
            enable = true;
            deploymentMode = "authenticated";
            deploymentExposure = "private";
            bind = "tailnet";
            publicUrl = "http://my-host.tailnet.ts.net:3100";
            agentClis.enable = true;
            environmentFile = "/run/agenix/paperclip.env";
            # database defaults to a locally-provisioned Postgres
          };

          services.tailscale.enable = true;
        })
      ];
    };
  };
}
```

`/run/agenix/paperclip.env` (or any sops/agenix-managed file) should contain:

```sh
BETTER_AUTH_SECRET=...                # openssl rand -hex 32
ANTHROPIC_API_KEY=...                 # optional
OPENAI_API_KEY=...                    # optional
```

### Module options

| Option | Default | Notes |
|---|---|---|
| `services.paperclip.enable` | `false` | |
| `services.paperclip.package` | `pkgs.paperclip` | Overlay in the flake's package |
| `services.paperclip.host` | `"127.0.0.1"` | Bind address |
| `services.paperclip.port` | `3100` | |
| `services.paperclip.bind` | `"loopback"` | `loopback`, `lan`, `tailnet` |
| `services.paperclip.deploymentMode` | `"local_trusted"` | or `"authenticated"` |
| `services.paperclip.deploymentExposure` | `"private"` | or `"public"` |
| `services.paperclip.publicUrl` | `null` | Required for `authenticated` + non-loopback bind |
| `services.paperclip.stateDir` | `"/var/lib/paperclip"` | `$PAPERCLIP_HOME` |
| `services.paperclip.database.mode` | `"postgresql"` | `postgresql` / `embedded` / `external` |
| `services.paperclip.database.url` | `null` | Required for `external` mode |
| `services.paperclip.environmentFile` | `null` | Path with `BETTER_AUTH_SECRET` etc. |
| `services.paperclip.agentClis.enable` | `false` | Adds claude-code/codex/opencode to PATH |
| `services.paperclip.openFirewall` | `false` | Leave false for tailnet-only deployments |

See `nix/module.nix` for the full schema.

### Database modes

- **`postgresql`** (default, recommended for servers): NixOS provisions a
  local Postgres via `services.postgresql`, peer auth over Unix socket. No
  passwords on disk.
- **`embedded`**: server starts its own bundled Postgres at
  `$PAPERCLIP_HOME/db`. Best for single-user installs.
- **`external`**: provide `database.url`. Use this for managed Postgres
  (RDS, Supabase, etc.).

## Dev shell

```sh
nix develop
# inside the shell:
pnpm install
pnpm dev
```

Contains Node 20, pnpm, every runtime binary listed above, plus
`postgresql` (for contributors who want an external DB during dev).
Playwright is pulled in via `pnpm install` rather than the Nix shell to
avoid version drift with the workspace's pinned `@playwright/test`.

## VM test

```sh
nix flake check                  # runs the basic VM test
nix build .#checks.x86_64-linux.vm
```

The test boots a NixOS VM, starts the module against a local Postgres, and
verifies `/api/health` returns `{"status":"ok"}`.

## Updating dependency hashes

### After bumping `pnpm-lock.yaml`

The `pnpmDeps` hash in `nix/package.nix` invalidates. Resolve:

1. Set the `hash` for `pnpmDeps` back to `lib.fakeHash`.
2. Run `nix build .#paperclip`. It fails with a hash mismatch.
3. Replace `fakeHash` with the printed `got: sha256-…` value.
4. Commit the bumped hash alongside the lockfile change.

### After bumping an agent CLI

`nix/agent-clis.nix` pins each CLI's per-architecture binary tarball with
its SRI hash. To bump, e.g., `claude-code`:

```sh
# Set new version, then for each arch:
nix-prefetch-url --type sha256 \
  "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-<NEW>.tgz"
nix hash to-sri --type sha256 <printed-base32-hash>
```

Repeat for `linux-arm64`. Update the two `hashes` entries. The binary
layout inside the tarball is occasionally changed by upstream — if so,
also update `binPath`. Confirm with:

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#paperclip-agent-clis
./result/bin/claude --version
```

### About unfree

Agent CLIs are proprietary. Either set `nixpkgs.config.allowUnfree = true`
in your NixOS config, or pin a per-package allowlist:

```nix
nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem (pkg.pname or "")
    [ "claude-code" "codex" "opencode" ];
```
