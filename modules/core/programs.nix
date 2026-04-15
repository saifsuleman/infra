{ ... }:
{
  flake.modules.nixos.core-programs =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        curl
        wget
        git
        neovim
        htop
      ];

      programs.neovim = {
        enable = true;
        defaultEditor = true;
      };
    };
}
