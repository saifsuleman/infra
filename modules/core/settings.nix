{ ... }:
{
  flake.modules.nixos.core-settings = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    programs.nix-ld = {
      enable = true;
    };

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.nvidia.acceptLicense = true;

    system.stateVersion = "25.05";
  };
}
