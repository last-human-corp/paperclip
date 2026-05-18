{ pkgs
, nixosModules
, paperclipPackage
, ...
}:

# Boots a NixOS VM with the paperclip module enabled against a locally
# provisioned Postgres, waits for the unit to come up, and curls the health
# endpoint documented at docs/deploy/tailscale-private-access.md:69-75.
pkgs.nixosTest {
  name = "paperclip-basic";

  nodes.machine = { config, pkgs, lib, ... }: {
    imports = [ nixosModules.paperclip ];

    nixpkgs.overlays = [
      (final: prev: {
        paperclip = paperclipPackage;
      })
    ];

    services.paperclip = {
      enable = true;
      bind = "loopback";
      host = "127.0.0.1";
      deploymentMode = "local_trusted";
      deploymentExposure = "private";
      database = {
        mode = "postgresql";
        createLocally = true;
      };
      # A dummy secret; local_trusted mode does not exercise auth flows but
      # the server still validates that BETTER_AUTH_SECRET is present.
      extraEnvironment.BETTER_AUTH_SECRET = "test-secret-test-secret-test-secret-32b";
    };

    # Modest VM resources — embedded Postgres is off here, but Node still
    # appreciates a couple of cores.
    virtualisation.memorySize = 2048;
    virtualisation.cores = 2;
  };

  testScript = ''
    machine.wait_for_unit("postgresql.service")
    machine.wait_for_unit("paperclip.service")
    machine.wait_for_open_port(3100)

    # Match the health check the docs prescribe.
    out = machine.succeed("curl -fsS http://127.0.0.1:3100/api/health")
    assert '"status":"ok"' in out, f"unexpected health response: {out!r}"
  '';
}
