{ inputs, ... }:
{
  flake.modules.homeManager.users-saifs-desktop-noctalia =
    { ... }:
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      programs.noctalia-shell.enable = true;

      xdg.configFile.noctalia.source = ./noctalia;
    };
}
