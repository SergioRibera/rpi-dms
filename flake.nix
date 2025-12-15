{
  description = "MangoWM implement DankMaterialShell for Raspberry Pi 3/4/5";
  outputs = {
    nixpkgs,
    nixos-generators,
    nixos-hardware,
    ...
  } @inputs: let
    buildSystems = ["x86_64-linux" "aarch64-linux"];
    forEachBuildSystem = nixpkgs.lib.genAttrs buildSystems;

    pkgsFor = system:
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
        [
          {
            networking.hostName = hostname;
            user.username = username;
            nixpkgs.hostPlatform = system;
          }
          ./home
          ./hosts/common
          inputs.home-manager.nixosModules.home-manager
          inputs.dms.nixosModules.dankMaterialShell
        ]
        ++ extraModules;
    };

    raspberryPiConfigs = [
      {
        system = "aarch64-linux";
        format = "sd-aarch64";
        hostname = "raspberrypi-aarch64";
        username = "s4rch";
        extraModules = [
          ./hosts/aarch64.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ];
      }
      {
        system = "armv7l-linux";
        format = "sd-armv7l";
        hostname = "raspberrypi-armv7l";
        username = "s4rch";
        extraModules = [
          ./hosts/armv7l.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-armv7l.nix"
        ];
      }
    ];

    mkNixosConfig = {
      system,
      hostname,
      username,
      extraModules ? [],
      ...
    }:
      nixpkgs.lib.nixosSystem (nixosBaseArgs username system hostname extraModules);

    mkSdImage = {
      system,
      format,
      hostname,
      username,
      extraModules ? [],
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
  in {
    apps = forEachBuildSystem (system: let
      pkgs = pkgsFor system;
      
      # Función para crear apps de VM para cada configuración
      vmApps = builtins.listToAttrs (builtins.map (cfg: {
        name = "run-${cfg.system}";
        value = {
          type = "app";
          program = toString (pkgs.writeScript "run-${cfg.system}-vm" ''
            #!${pkgs.runtimeShell}
            set -e
            
            echo "Building VM for ${cfg.hostname}..."
            
            echo "Building SD image for ${cfg.hostname}..."
            nix build .#${cfg.hostname} --out-link ./result-sd-${cfg.hostname}
            
            IMAGE_PATH="./result-sd-${cfg.hostname}/sd-image/nixos-sd-image-*.img"
            if [ ! -f $IMAGE_PATH ]; then
              IMAGE_PATH="./result-sd-${cfg.hostname}/nixos-sd-image-*.img"
            fi
            
            if [ ! -f $IMAGE_PATH ]; then
              echo "Error: Could not find image file"
              exit 1
            fi
            
            echo "Starting QEMU VM for ${cfg.hostname}..."
            
            QEMU_IMAGE="./qemu-${cfg.hostname}.img"
            cp $IMAGE_PATH $QEMU_IMAGE
            
            ${pkgs.qemu}/bin/qemu-img resize $QEMU_IMAGE +4G
            
            if [ "${cfg.system}" = "aarch64-linux" ]; then
              ${pkgs.qemu}/bin/qemu-system-aarch64 \
                -machine virt \
                -cpu cortex-a57 \
                -m 2048 \
                -drive file=$QEMU_IMAGE,format=raw \
                -device virtio-gpu-pci \
                -device qemu-xhci \
                -device usb-kbd \
                -device usb-mouse \
                -nic user,hostfwd=tcp::2222-:22 \
                -nographic \
                -serial mon:stdio
            else
              ${pkgs.qemu}/bin/qemu-system-arm \
                -machine virt \
                -cpu cortex-a15 \
                -m 1024 \
                -drive file=$QEMU_IMAGE,format=raw \
                -device virtio-gpu-pci \
                -device qemu-xhci \
                -device usb-kbd \
                -device usb-mouse \
                -nic user,hostfwd=tcp::2222-:22 \
                -nographic \
                -serial mon:stdio
            fi
          '');
        };
      }) raspberryPiConfigs);
      
    in {
      fmt = {
        type = "app";
        program = "${pkgs.writeShellScript "fmt-all" ''
          find . -name '*.nix' -type f -exec ${pkgs.nixfmt-rfc-style}/bin/nixfmt {} \;
        ''}";
      };
    } // vmApps);

    packages."x86_64-linux" = let
      allImages = builtins.listToAttrs (builtins.map
        (cfg: {
          name = cfg.hostname;
          value = mkSdImage cfg;
        })
        raspberryPiConfigs);
    in {
      inherit (allImages) raspberrypi-aarch64 raspberrypi-armv7l;

      all-images = let
        pkgs = pkgsFor "x86_64-linux";
      in
        pkgs.symlinkJoin {
          name = "all-images";
          paths = builtins.attrValues allImages;
        };
    };

    nixosConfigurations = builtins.listToAttrs (builtins.map
      (cfg: {
        name = cfg.hostname;
        value = mkNixosConfig cfg;
      })
      raspberryPiConfigs);
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
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  nixConfig = {
    builders-use-substitutes = true;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://arm.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCwyvRCYg3Fs="
      "arm.cachix.org-1:5BthnDvNABZQ8Q8QuBdWjT8v3AT4DSBB6cO9CTU7Hys="
    ];
    extra-platforms = ["aarch64-linux" "armv7l-linux"];
  };
}
