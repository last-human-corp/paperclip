{
  description = "Paperclip — open-source orchestration for zero-human AI companies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      devShellSystems = supportedSystems ++ [ "x86_64-darwin" "aarch64-darwin" ];

      forSystems = systems: f:
        nixpkgs.lib.genAttrs systems (system: f {
          inherit system;
          pkgs = import nixpkgs { inherit system; };
        });
    in
    {
      packages = forSystems supportedSystems ({ pkgs, system }: rec {
        paperclip = pkgs.callPackage ./nix/package.nix { };
        paperclip-agent-clis = pkgs.callPackage ./nix/agent-clis.nix { };
        default = paperclip;
      });

      devShells = forSystems devShellSystems ({ pkgs, system }: {
        default = pkgs.callPackage ./nix/dev-shell.nix { };
      });

      nixosModules = {
        paperclip = import ./nix/module.nix;
        default = self.nixosModules.paperclip;
      };

      checks = forSystems [ "x86_64-linux" ] ({ pkgs, system }: {
        vm = pkgs.callPackage ./nix/tests/basic.nix {
          inherit (self) nixosModules;
          paperclipPackage = self.packages.${system}.paperclip;
        };
      });

      # Convenience formatter target: `nix fmt`
      formatter = forSystems devShellSystems ({ pkgs, system }:
        pkgs.nixpkgs-fmt);
    };
}
