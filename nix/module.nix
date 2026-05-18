{ config, lib, pkgs, ... }:

let
  cfg = config.services.paperclip;

  defaultPackage =
    if pkgs ? paperclip
    then pkgs.paperclip
    else throw "services.paperclip: no `paperclip` package found in pkgs; set `services.paperclip.package` or overlay this flake's package.";

  inherit (lib)
    mkEnableOption mkOption mkIf mkMerge types literalExpression
    optionalAttrs optional concatStringsSep;

  localDatabaseUrl =
    "postgres:///${cfg.database.name}?host=/run/postgresql";

  databaseUrl =
    if cfg.database.mode == "external"
    then cfg.database.url
    else if cfg.database.mode == "postgresql"
    then localDatabaseUrl
    else null; # embedded: server picks its own port

  agentCliPackage =
    if cfg.agentClis.enable
    then [ (if cfg.agentClis.package != null then cfg.agentClis.package else pkgs.paperclip-agent-clis) ]
    else [ ];

  # Wrap the upstream package so the agent CLIs land on the unit's PATH when
  # opted in. Avoid mutating the derivation if nothing changes.
  resolvedPackage =
    if cfg.agentClis.enable then
      pkgs.symlinkJoin {
        name = "${cfg.package.name}-with-agent-clis";
        paths = [ cfg.package ] ++ agentCliPackage;
      }
    else cfg.package;

  baseEnv = {
    NODE_ENV = "production";
    HOST = cfg.host;
    PORT = toString cfg.port;
    SERVE_UI = if cfg.serveUi then "true" else "false";
    HOME = cfg.stateDir;
    PAPERCLIP_HOME = cfg.stateDir;
    PAPERCLIP_INSTANCE_ID = cfg.instanceId;
    PAPERCLIP_CONFIG = "${cfg.stateDir}/instances/${cfg.instanceId}/config.json";
    PAPERCLIP_DEPLOYMENT_MODE = cfg.deploymentMode;
    PAPERCLIP_DEPLOYMENT_EXPOSURE = cfg.deploymentExposure;
    PAPERCLIP_BIND = cfg.bind;
  }
  // optionalAttrs (cfg.publicUrl != null) { PAPERCLIP_PUBLIC_URL = cfg.publicUrl; }
  // optionalAttrs (databaseUrl != null) { DATABASE_URL = databaseUrl; }
  // cfg.extraEnvironment;

in
{
  options.services.paperclip = {
    enable = mkEnableOption "Paperclip orchestration server";

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      defaultText = literalExpression "pkgs.paperclip";
      description = "The paperclip package to run.";
    };

    user = mkOption {
      type = types.str;
      default = "paperclip";
      description = "System user the service runs as.";
    };

    group = mkOption {
      type = types.str;
      default = "paperclip";
      description = "System group the service runs as.";
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/paperclip";
      description = ''
        Where Paperclip stores its data: instance config, secrets,
        uploaded files, and (in embedded mode) its Postgres data dir.
        Becomes $PAPERCLIP_HOME and $HOME for the service.
      '';
    };

    instanceId = mkOption {
      type = types.str;
      default = "default";
      description = "Paperclip instance id (subdirectory under stateDir).";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        Address to bind on. For private Tailscale access set this to
        the tailnet IP, or use `bind = "tailnet"` and let Paperclip
        infer it via `tailscale ip -4`.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 3100;
      description = "TCP port to listen on.";
    };

    bind = mkOption {
      type = types.enum [ "loopback" "lan" "tailnet" ];
      default = "loopback";
      description = ''
        Bind preset (forwarded as PAPERCLIP_BIND). `tailnet` requires
        `tailscale` on PATH (the package wrapper provides it).
      '';
    };

    deploymentMode = mkOption {
      type = types.enum [ "local_trusted" "authenticated" ];
      default = "local_trusted";
      description = "PAPERCLIP_DEPLOYMENT_MODE.";
    };

    deploymentExposure = mkOption {
      type = types.enum [ "private" "public" ];
      default = "private";
      description = "PAPERCLIP_DEPLOYMENT_EXPOSURE.";
    };

    publicUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://desk.example.com";
      description = ''
        Canonical public URL (PAPERCLIP_PUBLIC_URL). Required when
        deploymentMode = "authenticated" and the service is reachable
        on anything other than loopback.
      '';
    };

    serveUi = mkOption {
      type = types.bool;
      default = true;
      description = "Serve the React UI from the same process (SERVE_UI=true).";
    };

    agentClis = {
      enable = mkEnableOption "bundled agent CLIs (claude-code, codex, opencode-ai)";
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        defaultText = literalExpression "pkgs.paperclip-agent-clis";
        description = "Override the agent CLI bundle (defaults to pkgs.paperclip-agent-clis).";
      };
    };

    database = {
      mode = mkOption {
        type = types.enum [ "postgresql" "embedded" "external" ];
        default = "postgresql";
        description = ''
          - `postgresql`: NixOS-managed local Postgres, peer auth via
            Unix socket. The recommended mode for server deployments.
          - `embedded`: server runs its own bundled Postgres. Good for
            single-user / development.
          - `external`: provide DATABASE_URL via `database.url`.
        '';
      };

      name = mkOption {
        type = types.str;
        default = "paperclip";
        description = "Database/role name (postgresql mode).";
      };

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = ''
          When `mode = "postgresql"`, also enable and provision
          services.postgresql here. Set false if you manage Postgres
          via a separate NixOS module.
        '';
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "postgres://paperclip:secret@db.internal:5432/paperclip";
        description = "Connection string used when `mode = \"external\"`.";
      };
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/agenix/paperclip.env";
      description = ''
        Path to an env file passed to systemd via `EnvironmentFile=`.
        Use this for secrets like `BETTER_AUTH_SECRET`, `OPENAI_API_KEY`,
        `ANTHROPIC_API_KEY`. Must be readable by the service user.
      '';
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''{ PAPERCLIP_STORAGE_PROVIDER = "local_disk"; }'';
      description = "Additional environment variables for the unit.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Open the listening port in `networking.firewall`. Leave false
        for tailnet-only deployments (Tailscale carries its own ACLs).
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.database.mode != "external" || cfg.database.url != null;
          message = "services.paperclip.database.mode = \"external\" requires database.url.";
        }
        {
          assertion = cfg.deploymentMode != "authenticated"
            || cfg.publicUrl != null
            || cfg.bind == "loopback";
          message = ''
            services.paperclip: deploymentMode = "authenticated" requires
            either `publicUrl` to be set or `bind = "loopback"`.
          '';
        }
      ];

      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.stateDir;
        createHome = false; # tmpfiles handles ownership/mode
        description = "Paperclip orchestration server";
      };
      users.groups.${cfg.group} = { };

      systemd.tmpfiles.rules = [
        "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/instances 0750 ${cfg.user} ${cfg.group} -"
      ];

      networking.firewall = mkIf cfg.openFirewall {
        allowedTCPPorts = [ cfg.port ];
      };

      systemd.services.paperclip = {
        description = "Paperclip orchestration server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ]
          ++ optional (cfg.database.mode == "postgresql" && cfg.database.createLocally) "postgresql.service";
        wants = [ "network-online.target" ]
          ++ optional (cfg.database.mode == "postgresql" && cfg.database.createLocally) "postgresql.service";

        environment = baseEnv;

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${resolvedPackage}/lib/paperclip";
          ExecStart = "${resolvedPackage}/bin/paperclip";
          Restart = "on-failure";
          RestartSec = 5;

          # Hardening — keep the service confined to its state dir.
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
          ReadWritePaths = [ cfg.stateDir ];
          RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
          RestrictNamespaces = true;
          LockPersonality = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          ProtectClock = true;
        } // optionalAttrs (cfg.environmentFile != null) {
          EnvironmentFile = cfg.environmentFile;
        };
      };
    }

    (mkIf (cfg.database.mode == "postgresql" && cfg.database.createLocally) {
      services.postgresql = {
        enable = true;
        ensureDatabases = [ cfg.database.name ];
        ensureUsers = [{
          name = cfg.user;
          ensureDBOwnership = true;
        }];
      };
    })
  ]);
}
