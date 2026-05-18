{ lib
, symlinkJoin
, buildNpmPackage
, fetchurl
, nodejs_20
, makeWrapper
}:

# These three CLIs are what the Dockerfile installs globally
# (Dockerfile:55-56). They are pulled directly from the npm registry tarball
# and packaged as thin Nix wrappers. We deliberately do NOT track every
# transitive dep through Nix — these tools live in fast-moving npm space and
# pin-via-hash is the pragmatic balance.
#
# To bump: change the `version` and replace the corresponding `hash`. Get the
# new hash via:
#   nix-prefetch-url --type sha256 \
#     https://registry.npmjs.org/<pkg>/-/<pkg>-<version>.tgz

let
  mkNpmTool =
    { pname
    , version
    , scope ? ""
    , hash
    , binName ? pname
    }:
    let
      url =
        if scope == ""
        then "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz"
        else "https://registry.npmjs.org/@${scope}/${pname}/-/${pname}-${version}.tgz";
    in
    buildNpmPackage {
      inherit pname version;

      src = fetchurl { inherit url hash; };

      # npm install of a published tarball; no lockfile expected.
      dontNpmBuild = true;
      npmDepsHash = lib.fakeHash;

      nativeBuildInputs = [ makeWrapper ];

      meta = with lib; {
        description = "Agent CLI bundled for Paperclip (${pname}@${version})";
        license = licenses.unfree; # most agent CLIs are proprietary
        platforms = [ "x86_64-linux" "aarch64-linux" ];
        mainProgram = binName;
      };
    };

  claude-code = mkNpmTool {
    pname = "claude-code";
    scope = "anthropic-ai";
    version = "0.0.0"; # filled in at first build via fakeHash
    hash = lib.fakeHash;
    binName = "claude";
  };

  codex = mkNpmTool {
    pname = "codex";
    scope = "openai";
    version = "0.0.0";
    hash = lib.fakeHash;
    binName = "codex";
  };

  opencode-ai = mkNpmTool {
    pname = "opencode-ai";
    version = "0.0.0";
    hash = lib.fakeHash;
    binName = "opencode";
  };

in
symlinkJoin {
  name = "paperclip-agent-clis";
  paths = [ claude-code codex opencode-ai ];

  passthru = { inherit claude-code codex opencode-ai; };

  meta = with lib; {
    description = "Bundle of agent CLIs Paperclip can drive (claude-code, codex, opencode-ai)";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
