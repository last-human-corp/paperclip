{ lib
, stdenv
, nodejs_20
, pnpm_9
, fetchPnpmDeps
, pnpmConfigHook
, makeWrapper
, cacert
, # runtime PATH deps (kept in sync with Dockerfile)
  git
, gh
, ripgrep
, openssh
, jq
, python3
, coreutils
, bash
, curl
, wget
, tailscale
}:

let
  # Pin to pnpm 9 because the workspace declares `packageManager: pnpm@9.15.4`
  # and writes `lockfileVersion: '9.0'`. Newer pnpm majors (10/11) reject
  # this lockfile with ERR_PNPM_LOCKFILE_CONFIG_MISMATCH because they expect
  # the `overridesChecksum` field that pnpm 9 doesn't emit.
  pnpm = pnpm_9;

  src = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      let
        base = baseNameOf path;
        rel = lib.removePrefix (toString ../. + "/") (toString path);
      in
      # Exclude obviously-large/irrelevant trees up front so the source closure
      # stays small. Build artefacts (dist/, *.tsbuildinfo, etc.) are also
      # excluded — pnpm + the workspace builds regenerate them.
      !(
        base == "node_modules"
        || base == "result"
        || base == ".git"
        || base == ".github"
        || base == "data"
        || base == ".paperclip"
        || base == ".paperclip-local"
        || base == ".pnpm-store"
        || base == "coverage"
        || base == "dist"
        || base == "storybook-static"
        || base == ".DS_Store"
        || base == "nix"
        || base == "flake.nix"
        || base == "flake.lock"
        || lib.hasSuffix ".tsbuildinfo" base
      );
  };

  meta = with lib; {
    description = "Open-source orchestration for zero-human AI companies";
    homepage = "https://github.com/paperclipai/paperclip";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "paperclip";
  };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "paperclip";
  # Pinning the version is intentional: bump it in a single place when the
  # workspace root package.json gains a version, or on release tags.
  version = "0-unstable";

  inherit src;

  nativeBuildInputs = [
    nodejs_20
    pnpm
    (pnpmConfigHook.override { pnpm = pnpm_9; })
    makeWrapper
    cacert
    python3 # node-gyp for any native module rebuilds
  ];

  # Native modules (better-sqlite3, sharp, etc.) may need a real C toolchain
  # at install time. stdenv already provides gcc/make.
  buildInputs = [ ];

  # pnpmConfigHook does the heavy lifting:
  #   - resolves dependencies from `pnpmDeps` (offline fetch below)
  #   - honours `pnpm.patchedDependencies` and `pnpm.overrides` in package.json
  #   - runs lifecycle scripts for native modules
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_9;
    # fetcherVersion 3 is the current pnpm fetcher (fetcherVersion 1/2 are
    # deprecated and removed in 26.11). Works with pnpm 9 + lockfileVersion 9.0.
    fetcherVersion = 3;
    # Bumped whenever pnpm-lock.yaml changes — see doc/NIX.md
    # "Updating dependency hashes".
    hash = "sha256-37YTtHP7bOrfb7o+qx0FyLexS22mEDjqSI7Es2i1mPg=";
  };

  # The workspace declares pnpm@9.15.4 via packageManager; corepack would
  # normally enforce that. In Nix we use the pinned pnpm derivation
  # directly, so disable corepack's strict check.
  COREPACK_ENABLE_STRICT = "0";

  # Mirror the Dockerfile build sequence (Dockerfile:46-49). Build order
  # matters: ui first (consumed by server's static assets), then plugin-sdk
  # (used by adapters), then server (the runtime entry point).
  buildPhase = ''
    runHook preBuild

    # pnpmConfigHook runs `pnpm install --ignore-scripts` to keep the
    # configure phase hermetic, so native-module install hooks (sqlite3,
    # better-sqlite3, sharp) are never executed. Without those, sqlite3's
    # node bindings are missing and the server crashes at startup via
    # `@cursor/sdk`. Rebuild them here from source.
    #
    # `prebuild-install` (sqlite3's fast path) needs network access for
    # GitHub release downloads, so it always fails inside the Nix sandbox
    # and falls back to `node-gyp rebuild` — that's what we want.
    #
    # The store-dir is pinned to what pnpmConfigHook set up, because pnpm
    # rebuild otherwise picks the global default (~/.local/share/pnpm/store)
    # and refuses to link against the existing node_modules.
    storeDir="$(awk '/^storeDir:/ {print $2}' node_modules/.modules.yaml)"
    for pkg in sqlite3 better-sqlite3 sharp; do
      # `ls` is the most portable way to test "any file matches a glob"
      # in plain sh — compgen is bash-only and the build runs under sh.
      if ls -d node_modules/.pnpm/"$pkg"@* > /dev/null 2>&1; then
        echo "Rebuilding native module: $pkg"
        pnpm --store-dir "$storeDir" rebuild "$pkg"
      fi
    done

    pnpm --filter @paperclipai/ui build
    pnpm --filter @paperclipai/plugin-sdk build
    pnpm --filter @paperclipai/server build

    test -f server/dist/index.js \
      || (echo "ERROR: server build output missing" >&2; exit 1)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/paperclip
    # Copy the entire workspace; node_modules contain native prebuilds and
    # workspace symlinks that must be preserved as-is.
    cp -r --reflink=auto . $out/lib/paperclip/

    # Wrapper mirrors the Dockerfile CMD (Dockerfile:88-89). PATH carries
    # every external binary the server may exec at runtime.
    mkdir -p $out/bin
    makeWrapper ${nodejs_20}/bin/node $out/bin/paperclip \
      --add-flags "--import" \
      --add-flags "$out/lib/paperclip/server/node_modules/tsx/dist/loader.mjs" \
      --add-flags "$out/lib/paperclip/server/dist/index.js" \
      --prefix PATH : ${lib.makeBinPath [
        nodejs_20
        git
        gh
        ripgrep
        openssh
        jq
        python3
        coreutils
        bash
        curl
        wget
        tailscale
      ]} \
      --set NODE_ENV production

    runHook postInstall
  '';

  # The server build re-runs typecheck implicitly; skip the heavy test
  # suite at package-build time. CI runs it separately.
  doCheck = false;

  inherit meta;
})
