{
  description = "dblk build cache, packaged from upstream release binaries";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        dblk = pkgs.callPackage ./package.nix { };
        default = dblk;
      });

      darwinModules.default = ./modules/darwin.nix;
      nixosModules.default = ./modules/nixos.nix;
    };
}
