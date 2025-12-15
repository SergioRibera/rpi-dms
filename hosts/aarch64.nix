{ pkgs, ... }:
let
  kernelBundle = pkgs.linuxAndFirmware.v6_12_61;
in
{
  imports = [
    ./common/raspberrypi.nix
    ./common-options.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_rpi5;
  boot.loader.raspberryPi = {
    firmwarePackage = kernelBundle.raspberrypifw;
    bootloader = "kernel";
  };
  # hardware.raspberry-pi."4".fkms-3d.enable = true;

  # hardware.deviceTree = {
  #   overlays = [
  #     "${pkgs.device-tree_rpi.overlays}/vc4-fkms-v3d.dtbo"
  #     "${pkgs.device-tree_rpi.overlays}/vc4-fkms-v3d-pi4.dtbo"
  #     (pkgs.writeText "dw-hdmi-overlay" ''
  #       /dts-v1/;
  #       /plugin/;
  #       / {
  #         compatible = "brcm,bcm2711";
  #         fragment@0 {
  #           target = <&hdmi>;
  #           __overlay__ {
  #             status = "okay";
  #           };
  #         };
  #       };
  #     '')
  #   ];
  # };

  #  firmwareConfig = ''
  #    # Enable audio HDMI
  #    dtparam=audio=on
  #    # GPU memory (ajusta según necesidades)
  #    gpu_mem=256
  #    # Enable FKMS
  #    dtoverlay=vc4-fkms-v3d
  #    # Deshabilitar overscan
  #    disable_overscan=1
  #    # Configuración para dw-hdmi
  #    hdmi_force_hotplug=1
  #    hdmi_group=2
  #    hdmi_mode=87
  #    hdmi_cvt=1920 1080 60 6 0 0 0
  #    # Habilitar USB y periféricos
  #    dtparam=usb=on
  #  '';

  # Módulos del kernel necesarios
  # boot.initrd.availableKernelModules = [
  #   "usbhid"
  #   "usb_storage"
  #   "xhci_pci"
  #   "xhci_hcd"
  #   "usbhid"
  #   "hid_generic"
  #   "hid_apple"
  #   "hid_logitech"
  # ];

  # Parámetros del kernel
  # boot.kernelParams = [
  #   # Configuración de memoria
  #   "cma=64M"
  #   # Consola serial
  #   "console=ttyAMA0,115200"
  #   "console=tty1"
  #   # Habilitar modo 64-bit
  #   "arm_64bit=1"
  #   # Para dw-hdmi
  #   "drm_kms_helper.fbdev_emulation=1"
  #   "drm_kms_helper.poll=0"
  # ];
}
