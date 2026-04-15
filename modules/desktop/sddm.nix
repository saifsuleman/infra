{ ... }:
{
  flake.modules.nixos.desktop-sddm =
    { ... }:
    {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
}
