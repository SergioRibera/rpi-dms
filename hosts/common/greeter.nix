{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  user = config.user.username;

  cacheDir = "/var/lib/dms-greeter";
  logPath = "/tmp/dms-greeter.log";

  compositorPackage = config.programs.mango.package;

  greeterScript = pkgs.writeShellScriptBin "dms-greeter" ''
    export PATH=$PATH:${
      lib.makeBinPath [
        pkgs.quickshell
        compositorPackage
      ]
    }

    exec sh ${
      inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default
    }/quickshell/Modules/Greetd/assets/dms-greeter \
      --cache-dir ${cacheDir} \
      --command mango \
      -p ${inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/quickshell/dms \
  '';
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        inherit user;
        command = "${greeterScript}/bin/dms-greeter";
      };
    };
  };

  fonts.packages = with pkgs; [
    fira-code
    inter
    material-symbols
  ];

  systemd.tmpfiles.rules = [
    "d '${cacheDir}' 0750 ${user} ${user} - -"
  ];

  systemd.services.greetd.preStart =
    let
      jq = "${pkgs.jq}/bin/jq";
    in
    ''
      cd ${cacheDir}

      if [ -f session.json ]; then
        copy_wallpaper() {
          local path=$(${jq} -r ".$1 // empty" session.json)
          if [ -f "$path" ]; then
            cp "$path" "$2"
            ${jq} ".$1 = \"${cacheDir}/$2\"" session.json > session.tmp
            mv session.tmp session.json
          fi
        }

        copy_wallpaper "wallpaperPath" "wallpaper"
        copy_wallpaper "wallpaperPathLight" "wallpaper-light"
        copy_wallpaper "wallpaperPathDark" "wallpaper-dark"
      fi

      if [ -f settings.json ]; then
        if cp "$(${jq} -r '.customThemeFile // empty' settings.json)" custom-theme.json 2>/dev/null; then
          mv settings.json settings.orig.json
          ${jq} '.customThemeFile = "${cacheDir}/custom-theme.json"' settings.orig.json > settings.json
        fi
      fi

      mv dms-colors.json colors.json 2>/dev/null || true
      chown ${user}:${user} * 2>/dev/null || true
    '';

  systemd.services.greetd.serviceConfig = {
    StandardOutput = "file:${logPath}";
    StandardError = "file:${logPath}";
  };
}
