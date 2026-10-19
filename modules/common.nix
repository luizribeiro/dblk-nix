{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.services.dblk;
in
{
  options.services.dblk = {
    enable = mkEnableOption ''
      the dblk build cache: a daemon per logged-in user, with cargo pointed
      at it through RUSTC_WRAPPER
    '';

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = { DBLK_STORE_MAX_BYTES = "50G"; };
      description = "DBLK_* settings for the daemon; see `dblkc cached --help`.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    # dblk-rustc passes straight through to rustc when no daemon is
    # listening, so users without one still build normally.
    environment.variables.CARGO_BUILD_RUSTC_WRAPPER = "${cfg.package}/bin/dblk-rustc";
  };
}
