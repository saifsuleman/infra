{ ... }:
{
  flake.modules.nixos.core-options =
    { lib, ... }:
    {
      options.machine = {
        desktop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this machine has a desktop environment";
        };

        linux = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this machine is running on Linux";
        };
      };
    };
}
