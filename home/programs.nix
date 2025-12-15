{
  config,
  inputs,
  ...
}:
let
  inherit (config) shell user;
in
{
  imports = [
    ./shell
    ./tools/bat.nix
    ./tools/git.nix
  ];

  home-manager.users.${user.username} = (
    { ... }:
    {
      imports = [
        inputs.dms.homeModules.dankMaterialShell.default
      ];
      programs = {
        carapace = {
          enable = shell.name == "nushell";
          enableNushellIntegration = true;
        };
        dankMaterialShell = {
          enable = true;
          systemd = {
            enable = true; # Systemd service for auto-start
            restartIfChanged = true; # Auto-restart dms.service when dankMaterialShell changes
          };

          # Core features
          enableSystemMonitoring = false; # System monitoring widgets (dgop)
          enableVPN = true; # VPN management widget
          enableDynamicTheming = true; # Wallpaper-based theming (matugen)
          enableAudioWavelength = false; # Audio visualizer (cava)
          enableCalendarEvents = true; # Calendar integration (khal)
        };
      };
    }
  );
}
