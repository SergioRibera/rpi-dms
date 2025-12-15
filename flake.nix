{
  description = "MangoWM implement DankMaterialShell for Raspberry Pi 3/4/5";
  outputs =
    {
      self,
      nixpkgs,
      nixos-raspberrypi,
      ...
    }@inputs:
    let
      buildSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachBuildSystem = nixpkgs.lib.genAttrs buildSystems;

      lib = nixpkgs.lib;
      baseLib = nixpkgs.lib;
      origMkRemovedOptionModule = baseLib.mkRemovedOptionModule;
      patchedLib = lib.extend (
        final: prev: {
          mkRemovedOptionModule =
            optionName: replacementInstructions:
            let
              key = "removedOptionModule#" + final.concatStringsSep "_" optionName;
            in
            { options, ... }:
            (origMkRemovedOptionModule optionName replacementInstructions { inherit options; })
            // {
              inherit key;
            };
        }
      );

      pkgsFor =
        system:
        (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = with nixos-raspberrypi.overlays; [
            inputs.rust.overlays.default
            inputs.mac-style-plymouth.overlays.default

            bootloader
            vendor-pkgs
            # kernel-and-firmware
            vendor-firmware
            vendor-kernel

            (final: prev: {
              kbd = prev.kbd // {
                gzip = prev.gzip;
              };
            })
          ];
        });

      nixosBaseArgs = username: system: hostname: extraModules: {
        inherit system;
        lib = patchedLib;
        specialArgs = {
          inherit self inputs nixos-raspberrypi;
          pkgs = pkgsFor system;
        };
        modules =
          with nixos-raspberrypi.nixosModules;
          [
            nixos-raspberrypi.lib.inject-overlays-global
            nixos-raspberrypi.lib.inject-overlays
            {
              networking.hostName = hostname;
              user.username = username;
              nixpkgs.hostPlatform = system;
            }
            ./home
            ./hosts/common
            inputs.mango.nixosModules.mango
            inputs.home-manager.nixosModules.home-manager

            trusted-nix-caches
            nixpkgs-rpi
            usb-gadget-ethernet # Configures USB Gadget/Ethernet - Ethernet emulation over USB

            sd-image
          ]
          ++ extraModules;
      };

      raspberryPiConfigs = [
        {
          system = "aarch64-linux";
          format = "sd-aarch64";
          hostname = "raspberrypi-aarch64";
          username = "s4rch";
          extraModules = with nixos-raspberrypi.nixosModules; [
            ./hosts/aarch64.nix
            raspberry-pi-4.base
            raspberry-pi-4.display-vc4 # "regular" display connected
          ];
        }
        {
          system = "armv7l-linux";
          format = "sd-armv7l";
          hostname = "raspberrypi-armv7l";
          username = "s4rch";
          extraModules = with nixos-raspberrypi.nixosModules; [
            ./hosts/armv7l.nix
            raspberry-pi-3.base
          ];
        }
      ];

      mkNixosConfig =
        {
          system,
          hostname,
          username,
          extraModules ? [ ],
          ...
        }:
        nixos-raspberrypi.lib.nixosSystem (nixosBaseArgs username system hostname extraModules);

      mkSdImage =
        {
          hostname,
          ...
        }:
        self.nixosConfigurations.${hostname}.config.system.build.sdImage;
    in
    {
      apps = forEachBuildSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          fmt = {
            type = "app";
            program = "${pkgs.writeShellScript "fmt-all" ''
              find . -name '*.nix' -type f -exec ${pkgs.nixfmt-rfc-style}/bin/nixfmt {} \;
            ''}";
          };
        }
      );

      packages."x86_64-linux" =
        let
          allImages = builtins.listToAttrs (
            builtins.map (cfg: {
              name = cfg.hostname;
              value = mkSdImage cfg;
            }) raspberryPiConfigs
          );
        in
        {
          inherit (allImages) raspberrypi-aarch64 raspberrypi-armv7l;

          all-images =
            let
              pkgs = pkgsFor "x86_64-linux";
            in
            pkgs.symlinkJoin {
              name = "all-images";
              paths = builtins.attrValues allImages;
            };
        };

      nixosConfigurations = builtins.listToAttrs (
        builtins.map (cfg: {
          name = cfg.hostname;
          value = mkNixosConfig cfg;
        }) raspberryPiConfigs
      );
    };

  inputs = {
    # nixpkgs.url = "github:nvmd/nixpkgs/modules-with-keys-25.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-style-plymouth = {
      url = "github:SergioRibera/s4rchiso-plymouth-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell?rev=7fb358bada0d3a229ec5ee6aaad0f9b64f367331"; # stable branch
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell?rev=26531fc46ef17e9365b03770edd3fb9206fcb460";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:DreamMaoMao/mango?rev=2258574e25f4612affdc92621c8aef70e5c134e1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  nixConfig = {
    builders-use-substitutes = true;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://arm.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCwyvRCYg3Fs="
      "arm.cachix.org-1:5BthnDvNABZQ8Q8QuBdWjT8v3AT4DSBB6cO9CTU7Hys="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    extra-platforms = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };
}
