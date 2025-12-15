{
  description = "MangoWM implement DankMaterialShell for Raspberry Pi 3/4/5";
  outputs =
    {
      nixpkgs,
      nixos-generators,
      ...
    }@inputs:
    let
      buildSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachBuildSystem = nixpkgs.lib.genAttrs buildSystems;

      pkgsFor =
        system:
        (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            inputs.rust.overlays.default
            inputs.mac-style-plymouth.overlays.default
          ];
        });

      nixosBaseArgs = username: system: hostname: extraModules: {
        inherit system;
        specialArgs = {
          inherit inputs;
          pkgs = pkgsFor system;
        };
        modules =
          with inputs.nixos-raspberrypi.nixosModules;
          [
            {
              networking.hostName = hostname;
              user.username = username;
              nixpkgs.hostPlatform = system;
            }
            ./home
            ./hosts/common
            inputs.mango.nixosModules.mango
            inputs.home-manager.nixosModules.home-manager

            inputs.nixos-raspberrypi.lib.inject-overlays
            trusted-nix-caches
            usb-gadget-ethernet # Configures USB Gadget/Ethernet - Ethernet emulation over USB
            inputs.nixos-raspberrypi.lib.inject-overlays-global
          ]
          ++ extraModules;
      };

      raspberryPiConfigs = [
        {
          system = "aarch64-linux";
          format = "sd-aarch64";
          hostname = "raspberrypi-aarch64";
          username = "s4rch";
          extraModules = with inputs.nixos-raspberrypi.nixosModules; [
            ./hosts/aarch64.nix
            raspberry-pi-4.base
            raspberry-pi-4.display-vc4 # "regular" display connected
            raspberry-pi-4.display-vc4
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ];
        }
        {
          system = "armv7l-linux";
          format = "sd-armv7l";
          hostname = "raspberrypi-armv7l";
          username = "s4rch";
          extraModules = with inputs.nixos-raspberrypi.nixosModules; [
            ./hosts/armv7l.nix
            raspberry-pi-3.base
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-armv7l.nix"
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
        nixpkgs.lib.nixosSystem (nixosBaseArgs username system hostname extraModules);

      mkSdImage =
        {
          system,
          format,
          hostname,
          username,
          extraModules ? [ ],
          ...
        }:
        nixos-generators.nixosGenerate {
          inherit system format;
          modules = (nixosBaseArgs username system hostname extraModules).modules;
          specialArgs = {
            inherit inputs;
            pkgs = pkgsFor system;
          };
        };
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
