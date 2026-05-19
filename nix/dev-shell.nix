{ mkShell
, nodejs_20
, pnpm
, git
, gh
, ripgrep
, openssh
, jq
, python3
, curl
, wget
, tailscale
, postgresql
}:

# Dev shell parity with the Dockerfile's base image so that `pnpm dev`,
# `pnpm test:run`, and `pnpm test:e2e` all work inside `nix develop` without
# polluting the host system.
mkShell {
  name = "paperclip-dev";

  packages = [
    nodejs_20
    pnpm

    # Runtime binaries exec'd by the server and agent CLIs
    git
    gh
    ripgrep
    openssh
    jq
    python3
    curl
    wget
    tailscale

    # Useful for local Postgres if the contributor opts out of embedded mode
    postgresql
  ];

  shellHook = ''
    echo "paperclip dev shell ready — node $(node --version), pnpm $(pnpm --version)"
  '';
}
