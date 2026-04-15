{ inputs, ... }:
let
  home-manager-base =
    { ... }:
    {
      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;

        sharedModules = [
          (
            {
              config,
              lib,
              pkgs,
              ...
            }:
            {
              home.homeDirectory = lib.mkDefault (
                if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}"
              );

              home.stateVersion = "25.05";
            }
          )
        ];
      };
    };
in
{
  flake-file.inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  flake.modules.nixos.core-home-manager = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      home-manager-base
    ];
  };
}
