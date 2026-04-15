{ ... }:
{
  flake-file.inputs.hyprland = {
    url = "github:hyprwm/Hyprland";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.nixos.desktop-hyprland =
    { pkgs, ... }:
    {
      programs.hyprland.enable = true;

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      services.xserver.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
        config.common.default = "*";
      };

      services.pipewire.enable = true;

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        XDG_SESSION_TYPE = "wayland";
      };
    };
}
