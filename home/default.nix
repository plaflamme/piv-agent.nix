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
    enable = lib.mkEnableOption "Enables piv-agent";
  };
  config = lib.mkIf cfg.enable {
  };
}
