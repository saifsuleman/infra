{ inputs, ... }:
{
  flake.modules.nixos.users-saifs =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      users.users.saifs = {
        isNormalUser = true;
        shell = pkgs.nushell;
        extraGroups = [
          "wheel"
          "video"
          "audio"
          "networkmanager"
        ];
      };

      home-manager.users.saifs = {
        imports =
          with inputs.self.modules.homeManager;
          [
            users-saifs-core-programs
          ]
          ++ lib.optionals config.machine.desktop [
            # Desktop Only
            users-saifs-desktop-programs
            users-saifs-desktop-noctalia
            desktop-zen-browser
          ]
          ++ lib.optionals config.machine.linux [
            # Linux Only
          ];

        programs.nushell.enable = true;

        home.username = "saifs";
      };
    };
}
