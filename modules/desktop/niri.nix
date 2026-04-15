{ ... }:
{
  flake-file.inputs.niri = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.nixos.desktop-niri =
    { pkgs, ... }:
    {
      programs.niri.enable = true;

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        config.common.default = "*";
      };

      services.pipewire.enable = true;

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        XDG_SESSION_TYPE = "wayland";
      };
    };
}
