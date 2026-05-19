{ lib
, stdenv
, nodejs_20
, pnpm_9
, fetchPnpmDeps
, pnpmConfigHook
, makeWrapper
, cacert
, # node-gyp@8 (bundled in node 20 ecosystem) imports `distutils`, which
  # Python 3.12+ removed. Use a Python with setuptools, which ships a
  # `distutils` compatibility shim.
  python3
, # runtime PATH deps (kept in sync with Dockerfile)
  git
, gh
, ripgrep
, openssh
, jq
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

  # Point node-gyp at the Node.js header tarball bundled with nodejs_20.
  # Without this, node-gyp tries to fetch from nodejs.org during build —
  # impossible inside the Nix sandbox.
  npm_config_nodedir = nodejs_20;

  # Force node-gyp to use a Python that has setuptools (provides a
  # `distutils` shim removed from Python 3.12+ stdlib). The bundled
  # node-gyp@8 still imports `distutils.version` and fails otherwise.
  npm_config_python =
    "${python3.withPackages (ps: [ ps.setuptools ])}/bin/python";

  # Mirror the Dockerfile build sequence (Dockerfile:46-49). Build order
  # matters: ui first (consumed by server's static assets), then plugin-sdk
  # (used by adapters), then server (the runtime entry point).
  buildPhase = ''
    runHook preBuild

    # pnpmConfigHook runs `pnpm install --ignore-scripts` to keep the
    # configure phase hermetic, so native-module install hooks are never
    # executed. Without sqlite3's bindings the server crashes at startup
    # via `@cursor/sdk`. Build it directly with node-gyp here — `pnpm
    # rebuild` runs silently no-op'd in this environment, so we go around it.
    #
    # All three of these packages publish prebuilds, but those downloads
    # need network access (and prebuilds for some of them link against
    # glibc/musl differently than the sandbox provides). Compiling from the
    # vendored C sources is fully offline and stable.
    rebuild_node_module() {
      local pkg="$1"
      local pkg_dir
      pkg_dir=$(echo node_modules/.pnpm/"$pkg"@*/node_modules/"$pkg")
      if [ ! -d "$pkg_dir" ]; then
        echo "skip $pkg (not installed)" >&2
        return 0
      fi
      echo "Building native module: $pkg ($pkg_dir)"
      # Use the project-local node-gyp shipped by the package itself or by
      # the workspace; the Nix sandbox PATH doesn't include node-gyp.
      local gyp_rel
      if [ -x "$pkg_dir/node_modules/.bin/node-gyp" ]; then
        gyp_rel="node_modules/.bin/node-gyp"
        ( cd "$pkg_dir" && ./"$gyp_rel" rebuild --release ) \
          || { echo "ERROR: $pkg native build failed" >&2; exit 1; }
      else
        local gyp_abs="$PWD/node_modules/.bin/node-gyp"
        if [ ! -x "$gyp_abs" ]; then
          echo "ERROR: cannot find node-gyp for $pkg" >&2
          exit 1
        fi
        ( cd "$pkg_dir" && "$gyp_abs" rebuild --release ) \
          || { echo "ERROR: $pkg native build failed" >&2; exit 1; }
      fi
    }

    rebuild_node_module sqlite3
    rebuild_node_module better-sqlite3 || true   # only needed if used
    # sharp uses its own libvips prebuild approach; skip — the published
    # `@img/sharp-libvips-linux-*` packages already ship the right binary.

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

  # Skip stdenv's strip/patchelf passes over node_modules. Native modules
  # ship as pre-shipped .node files (sharp, sqlite3, esbuild, rollup, etc.)
  # designed to be portable as-is; patchelf'ing them is both slow (many
  # thousand files in a pnpm tree) and counter-productive — most are
  # static-pie binaries that fail with `cannot find section '.dynamic'`.
  # `autoPatchelfHook` is intentionally not in nativeBuildInputs.
  dontStrip = true;
  dontPatchELF = true;

  inherit meta;
})
