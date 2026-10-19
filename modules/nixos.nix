{ config, lib, ... }:

let
  cfg = config.services.dblk;
in
{
  imports = [ ./common.nix ];

  config = lib.mkIf cfg.enable {
    systemd.user.services.dblk-cached = {
      description = "dblk build-cache daemon";
      wantedBy = [ "default.target" ];
      unitConfig.ConditionUser = "!@system";
      environment = cfg.environment;
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} cached";
        Restart = "on-failure";
      };
    };
  };
}
