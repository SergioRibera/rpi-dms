{
  lib,
  config,
  ...
}:
{
  hardware = {
    graphics.enable = true;
    bluetooth = lib.mkIf config.bluetooth {
      enable = true;
      powerOnBoot = false;
    };
  };
}
