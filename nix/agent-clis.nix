{ lib
, stdenv
, symlinkJoin
, fetchurl
, autoPatchelfHook
, makeWrapper
, system
}:

# These three CLIs are what the Dockerfile installs globally
# (Dockerfile:55-56). Each upstream npm package is a small dispatcher that
# loads a platform-specific subpackage at install time. We skip the
# dispatcher and fetch the per-arch native binary directly — `buildNpmPackage`
# can't handle these tarballs (no package-lock.json, postinstall fetches
# binaries from npm at runtime), but the platform tarballs are simple enough
# to wrap as plain derivations.
#
# To bump a tool:
#   1. Set new `version`.
#   2. Re-prefetch each per-arch tarball and update the hash:
#        nix-prefetch-url --type sha256 <tarball-url>
#        nix hash to-sri --type sha256 <hash>
#   3. Confirm the binary layout inside the tarball hasn't changed.

let
  # System -> (npmArch, dynamic-link?)
  archInfo = {
    "x86_64-linux"  = { suffix = "linux-x64";   dynamicLinked = true; };
    "aarch64-linux" = { suffix = "linux-arm64"; dynamicLinked = true; };
  };

  info =
    archInfo.${system}
      or (throw "paperclip-agent-clis: unsupported system ${system}");

  mkBinary =
    { pname
    , version
    , binName
    , # path inside the extracted package directory (after `package/`) that
      # contains the executable. May contain placeholders {arch}.
      binPath
    , # set of per-arch SRI hashes keyed by archInfo.suffix
      hashes
    , # set of per-arch URLs keyed by archInfo.suffix
      urls
    , dynamicLinked ? info.dynamicLinked
    , # extra runtime libraries (rare — autoPatchelfHook handles most cases
      # by pulling in stdenv.cc.cc.lib for libstdc++)
      extraLibs ? [ ]
    }:
    stdenv.mkDerivation {
      inherit pname version;
      src = fetchurl {
        url = urls.${info.suffix};
        hash = hashes.${info.suffix};
      };

      sourceRoot = "package";

      nativeBuildInputs = lib.optional dynamicLinked autoPatchelfHook
        ++ [ makeWrapper ];
      buildInputs = lib.optionals dynamicLinked (extraLibs ++ [ stdenv.cc.cc.lib ]);

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 ${binPath} $out/bin/${binName}
        runHook postInstall
      '';

      meta = with lib; {
        description = "Agent CLI bundled for Paperclip (${pname}@${version})";
        license = licenses.unfree;
        platforms = builtins.attrNames archInfo;
        mainProgram = binName;
      };
    };

  claude-code = mkBinary {
    pname = "claude-code";
    version = "2.1.144";
    binName = "claude";
    binPath = "claude";
    urls = {
      "linux-x64"   = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-2.1.144.tgz";
      "linux-arm64" = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-2.1.144.tgz";
    };
    hashes = {
      "linux-x64"   = "sha256-6679jbV6yZ1hogNyqTs0gS95d1cCWeiPu6GikYw/otI=";
      "linux-arm64" = "sha256-EktgpkRV7kVMDHX07z2ViQJUbskOKYwhUIJLsl38LN8=";
    };
  };

  # codex ships as a static-pie ELF; no runtime patching needed.
  codex = mkBinary {
    pname = "codex";
    version = "0.131.0";
    binName = "codex";
    binPath =
      if system == "x86_64-linux"
      then "vendor/x86_64-unknown-linux-musl/codex/codex"
      else "vendor/aarch64-unknown-linux-musl/codex/codex";
    dynamicLinked = false;
    urls = {
      "linux-x64"   = "https://registry.npmjs.org/@openai/codex/-/codex-0.131.0-linux-x64.tgz";
      "linux-arm64" = "https://registry.npmjs.org/@openai/codex/-/codex-0.131.0-linux-arm64.tgz";
    };
    hashes = {
      "linux-x64"   = "sha256-hhPVznf5v7IO4oPv5NsW6n7qbRCauSQVIgF0mDJWET0=";
      "linux-arm64" = "sha256-A1JvTTH2qU08+mnfTXjKyskQCFgRiYPluas7xQABBcA=";
    };
  };

  opencode = mkBinary {
    pname = "opencode";
    version = "1.15.5";
    binName = "opencode";
    binPath = "bin/opencode";
    urls = {
      "linux-x64"   = "https://registry.npmjs.org/opencode-linux-x64/-/opencode-linux-x64-1.15.5.tgz";
      "linux-arm64" = "https://registry.npmjs.org/opencode-linux-arm64/-/opencode-linux-arm64-1.15.5.tgz";
    };
    hashes = {
      "linux-x64"   = "sha256-taZkHun5OsGO6VQ3ZAnnCDne+bsaRRpfPExtrerNy8Q=";
      "linux-arm64" = "sha256-O2hVGCK+aRHjL87VOKww6yMnzcFFJbMZoarA6vNq+V8=";
    };
  };

in
symlinkJoin {
  name = "paperclip-agent-clis";
  paths = [ claude-code codex opencode ];

  passthru = { inherit claude-code codex opencode; };

  meta = with lib; {
    description = "Bundle of agent CLIs Paperclip can drive (claude-code, codex, opencode)";
    license = licenses.unfree;
    platforms = builtins.attrNames archInfo;
  };
}
