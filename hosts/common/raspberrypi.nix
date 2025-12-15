{ pkgs, ... }:
{
  boot.loader.raspberryPi.bootloader = "kernel";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [
        "noatime"
        "discard"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];

  services.fstrim.enable = true;

  environment.systemPackages = with pkgs; [
    libraspberrypi
    picocom
  ];
}
