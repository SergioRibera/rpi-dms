{ ... }:
{
  # Prioritize performance over efficiency
  powerManagement.cpuFreqGovernor = "performance";

  bluetooth = false;

  terminal = {
    name = "alacritty";
    command = [
      "alacritty"
      "-e"
    ];
  };
  shell = {
    name = "nushell";
    command = [ "nu" ];
    privSession = [
      "nu"
      "--no-history"
    ];
  };

  user = {
    isNormalUser = true;
    browser = "firefox";
    groups = [
      "wheel"
      "video"
      "audio"
      "docker"
      "networkmanager"
      "input"
      "dialout"
    ];
  };
}
