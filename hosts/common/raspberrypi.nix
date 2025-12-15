{ pkgs, ... }:
{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
  };

  boot.loader.grub.enable = false;

  hardware.enableRedistributableFirmware = true;
  hardware.opengl.enable = true;

  services.fstrim.enable = true;
  
  services.openssh.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  services.xserver.enable = false;
  services.xserver.desktopManager.gnome.enable = false;
  
  systemd.services."serial-getty@ttyAMA0".enable = false;
  systemd.services."serial-getty@ttyS0".enable = false;

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    vcgencmd
  ];
}
