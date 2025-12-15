{ pkgs, config, ... }:
let
  inherit (config.user) username;

  tomlFormat = pkgs.formats.toml { };
in
with pkgs;
{
  home-manager.users."${username}" = {
    xdg.configFile."bottom/bottom.toml".source = tomlFormat.generate "bottom.toml" {
      flags = {
        dot_marker = true;
        enable_gpu = true;
      };
      processes = {
        tree = true;
        group_processes = false;
        process_memory_as_value = true;
        columns = [
          "PID"
          "Name"
          "CPU%"
          "Mem%"
          "R/s"
          "W/s"
          "User"
          "State"
          "GMem%"
          "GPU%"
        ];
      };
    };

    home.packages = [
      # Dev Utils
      (pkgs.neovim-unwrapped.overrideAttrs (
        attrs: prev: {
          postBuild = "rm -rf $out/share/applications";
        }
      ))
      neovide

      dive
      just

      # Js
      pnpm
      nodejs
      python314

      # Cargo extras
      cargo-expand

      # GUI
      nautilus
      # easyeffects
      # pwvucontrol
      # playerctl
    ];
  };
}
