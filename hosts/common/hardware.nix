{
  lib,
  config,
  ...
}:
{
  hardware = {
    pulseaudio.enable = false;
    graphics.enable = true;
    bluetooth = lib.mkIf config.bluetooth {
      enable = true;
      powerOnBoot = false;
    };
  };
}
