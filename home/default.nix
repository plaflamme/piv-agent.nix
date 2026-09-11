{
  config,
  lib,
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
  };

  config = lib.mkIf cfg.enable {
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
          # NOTE: credentials-directory is required by `piv-agent serve` but only read for age seeds, which we
          # don't support yet, so a non-existent runtime path is fine.
          ExecStart = "${cfg.package}/bin/piv-agent serve --credentials-directory=/dev/null --agent-types=ssh=0";
        };
      };
    };
  };
}
