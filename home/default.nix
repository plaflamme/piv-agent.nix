{
  config,
  lib,
  ...
}:
let
  cfg = config.services.piv-agent;

  socketPath = "piv-agent/ssh.socket";

  # Required by `piv-agent serve` but only read for age seeds, which we
  # don't support yet, so a non-existent runtime path is fine.
  credentialsDir = "%t/piv-agent/credentials";
in
{
  options.services.piv-agent = {
    enable = lib.mkEnableOption "the socket-activated piv-agent systemd user service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The piv-agent package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    sshAuthSock = {
      enable = true;
      initialization = {
        bash = ''
          unset SSH_AGENT_PID
          if [ "''${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/${socketPath}"
          fi
        '';
      };
      systemd.socketProviderUnit = "piv-agent.service";
    };

    systemd.user = {
      sockets."piv-agent" = {
        Unit.Description = "piv-agent socket activation";
        # systemd specifier syntax; %t is the user runtime directory ($XDG_RUNTIME_DIR)
        Socket.ListenStream = [ "%t/${socketPath}" ];
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
          ExecStart = "${cfg.package}/bin/piv-agent serve --agent-types=ssh=0";
          Environment = [ "CREDENTIALS_DIRECTORY=${credentialsDir}" ];
        };
      };
    };
  };
}
