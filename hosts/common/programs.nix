{ ... }:
{
  programs = {
    dconf.enable = true;
    nh = {
      enable = true;
      flake = "/etc/nixos";
    };
    ssh = {
      extraConfig = ''
        AddKeysToAgent yes
      '';
    };
  };
}
