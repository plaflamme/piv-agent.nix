{
  config,
  lib,
  ...
}:
let
  cfg = config.services.piv-agent;

  # systemd specifier syntax; %t is the user runtime directory ($XDG_RUNTIME_DIR)
  socketPath = "%t/piv-agent/ssh.socket";

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

    systemd.user = {
      sockets."piv-agent" = {
        Unit.Description = "piv-agent socket activation";
        Socket.ListenStream = [ socketPath ];
        Install.WantedBy = [ "sockets.target" ];
      };

      services."piv-agent" = {
        Unit.Description = "piv-agent service";
        Service = {
          ExecStart = "${cfg.package}/bin/piv-agent serve --agent-types=ssh=0";
          Environment = [ "CREDENTIALS_DIRECTORY=${credentialsDir}" ];
        };
      };
    };

    # Point the SSH client at the piv-agent socket.
    home.sessionVariables = {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/piv-agent/ssh.socket";
    };
  };
}
