{ inputs, ... }:
{
  flake-file.inputs = {
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.nixos.desktop-zen-browser =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        inputs.zen-browser.packages."${system}".default
      ];
    };

  flake.modules.homeManager.desktop-zen-browser =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        inputs.zen-browser.packages."${system}".default
      ];
    };
}
