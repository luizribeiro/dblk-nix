{ config, lib, ... }:

let
  cfg = config.services.dblk;
in
{
  imports = [ ./common.nix ];

  config = lib.mkIf cfg.enable {
    # A user agent starts once per logged-in user, each with its own cache
    # under that user's ~/.cache/dblk, where dblk-rustc looks by default.
    launchd.user.agents.dblk-cached = {
      command = "${lib.getExe cfg.package} cached >>\"$HOME/Library/Logs/dblk-cached.log\" 2>&1";
      environment = cfg.environment;
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        ProcessType = "Background";
      };
    };
  };
}
