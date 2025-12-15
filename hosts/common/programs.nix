{
  programs = {
    dconf.enable = true;
    nh = {
      enable = true;
      flake = "/etc/nixos";
    };
    ssh = {
      startAgent = true;
      extraConfig = ''
        AddKeysToAgent yes
      '';
    };
  };
}
