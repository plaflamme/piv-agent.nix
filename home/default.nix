{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.piv-agent;
in
{
  options.services.piv-agent = {
    enable = lib.mkEnableOption "the socket-activated piv-agent systemd user service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The piv-agent package to use.";
    };

    socket = lib.mkOption {
      type = lib.types.str;
      default = "piv-agent/ssh.socket";
      example = "piv-agent/my.socket";
      description = ''
        The SSH agent's socket; interpreted as a suffix to {env}`$XDG_RUNTIME_DIR`
        on Linux.
      '';
    };

    pinentry = {
      package = lib.mkPackageOption pkgs "pinentry-gnome3" {
        nullable = true;
        default = null;
        extraDescription = ''
          Which pinentry interface to use. If not `null`, it sets
          {option}`--pinentry-binary-name` command line option. Beware that
          `pinentry-gnome3` may not work on non-GNOME systems. You can fix it by
          adding the following to your configuration:
          ```nix
          home.packages = [ pkgs.gcr ];
          ```
        '';
      };

      program = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        example = "pinentry-wayprompt";
        description = ''
          Which program to search for in the configured `pinentry.package`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Grab the default binary name and fallback to expected value if `meta.mainProgram` not set
    services.piv-agent.pinentry.program = lib.mkOptionDefault (
      cfg.pinentry.package.meta.mainProgram or "pinentry"
    );

    home.packages = [ cfg.package ];

    sshAuthSock = {
      enable = true;
      initialization =
        let
          socketPath = "$${XDG_RUNTIME_DIR}/${cfg.socket}";
        in
        {
          bash = ''export SSH_AUTH_SOCK="${socketPath}"'';
          fish = ''set -x SSH_AUTH_SOCK "${socketPath}"'';
          nushell = "$env.SSH_AUTH_SOCK = $env.XDG_RUNTIME_DIR/${cfg.socket}";
        };
      systemd.socketProviderUnit = "piv-agent.service";
    };

    systemd.user = {
      sockets."piv-agent" = {
        Unit.Description = "piv-agent socket activation";
        # systemd specifier syntax; %t is the user runtime directory ($XDG_RUNTIME_DIR)
        Socket.ListenStream = [ "%t/${cfg.socket}" ];
        Install.WantedBy = [ "sockets.target" ];
      };

      services."piv-agent" = {
        Unit = {
          Description = "piv-agent service";
          Requires = "piv-agent.socket";
          After = "piv-agent.socket";
          RefuseManualStart = true;
        };
        Service = {
          ExecStart = lib.concatStringsSep " " (
            [
              "${cfg.package}/bin/piv-agent serve"
              # NOTE: credentials-directory is required by `piv-agent serve` but only read for age seeds, which we
              # don't support yet, so a non-existent runtime path is fine.
              "--credentials-directory=/dev/null"
              "--agent-types=ssh=0"
            ]
            ++ lib.optional (
              cfg.pinentry.package != null
            ) "--pinentry-binary-name=${lib.getExe' cfg.pinentry.package cfg.pinentry.program}"
          );
        };
      };
    };
  };
}
