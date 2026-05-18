{ mkShell
, nodejs_20
, pnpm_9
, git
, gh
, ripgrep
, openssh
, jq
, python3
, curl
, wget
, tailscale
, postgresql_17
, playwright-driver
}:

# Dev shell parity with the Dockerfile's base image so that `pnpm dev`,
# `pnpm test:run`, and `pnpm test:e2e` all work inside `nix develop` without
# polluting the host system.
mkShell {
  name = "paperclip-dev";

  packages = [
    nodejs_20
    pnpm_9

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
    postgresql_17

    # Playwright E2E tests
    playwright-driver
  ];

  shellHook = ''
    export PLAYWRIGHT_BROWSERS_PATH=${playwright-driver.browsers}
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
    echo "paperclip dev shell ready — node $(node --version), pnpm $(pnpm --version)"
  '';
}
