{ pkgs, ... }:
{
  imports = [
    ./common/raspberrypi.nix
    ./common-options.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_12;
    kernelParams = [
      "cma=64M"
      "console=ttyAMA0,115200"
      "console=tty1"
    ];
    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
    ];
  };

  # hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;
  # hardware.raspberry-pi."4".fkms-3d.enable = true;
}
