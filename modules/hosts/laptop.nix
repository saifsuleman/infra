{ inputs, ... }:
{
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = with inputs.self.modules.nixos; [
      core-home-manager
      core-settings
      core-programs
      core-options
      core-nvidia

      desktop-hyprland
      desktop-niri
      desktop-sddm

      users-saifs

      (import ../../hardware/laptop.nix)

      {
        networking.hostName = "laptop";
        time.timeZone = "Europe/London";

        hardware.bluetooth.enable = true;
        services.blueman.enable = true;

        networking.networkmanager.enable = true;

        machine.desktop = true;
        machine.linux = true;

        boot.loader.grub.enable = true;
        boot.loader.grub.efiSupport = true;
        boot.loader.grub.device = "nodev";
        boot.loader.efi.canTouchEfiVariables = true;
      }
    ];
  };
}
