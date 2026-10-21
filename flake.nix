{
  description = "My personal flake";
  inputs = {
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # No nixpkgs follows: tracks its own pin for the cached vendor kernel
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-color-lsp.url = "github:tonybutt/nixpkgs/color-lsp-init";
    # No nixpkgs follows: cache.numtide.com only holds builds against the
    # flake's own pin, so following ours turns every agent into a source build
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # No nixpkgs follows: hyprland.cachix.org only holds builds against
    # Hyprland's own pin, so following ours compiles Hyprland locally
    hyprland.url = "github:hyprwm/Hyprland";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    team-claude-skills = {
      url = "git+ssh://git@code.grail.tiberius.com/grail/team-claude-skills";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
        git-hooks.follows = "pre-commit-hooks";
      };
    };
    watchman = {
      url = "git+ssh://git@code.grail.tiberius.com/abutt/watchman";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
        git-hooks.follows = "pre-commit-hooks";
        home-manager.follows = "home-manager";
      };
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    # Stopgap for Alexays/Waybar#5316 — see overlays/waybar-hyprland-ipc.nix
    waybar-src = {
      url = "github:tonybutt/Waybar/hyprland-addressable-workspaces";
      flake = false;
    };
  };
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://cache.numtide.com"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      stylix,
      home-manager,
      hyprland,
      disko,
      sops-nix,
      deploy-rs,
      nixos-hardware,
      treefmt-nix,
      pre-commit-hooks,
      waybar-src,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (import ./overlays/brave-no-hw-encode.nix)
          (import ./overlays/brave-endpoint-verification.nix)
          (import ./overlays/brave-render-node.nix)
          (import ./overlays/waybar-hyprland-ipc.nix { inherit waybar-src; })
        ];
      };
      user = {
        username = "anthony";
        fullName = "Anthony Butt";
        work = {
          email = "abutt@tiberius.com";
          # Not id_ed25519_sk: it is a no-touch-required sk key, and Forgejo's
          # Go verifier rejects sk signatures lacking the user-presence flag,
          # so its commits never show as verified.
          signingKey = "~/.ssh/id_ed25519.pub";
          githubOrg = "tiberius-grail";
        };
        personal = {
          email = "anthony@abutt.io";
          signingKey = "~/.ssh/id_ed25519_personal.pub";
          githubUsername = "tonybutt";
        };
        sshKeys = [
          "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO9ZH1VvOc2+1tAkzQzNwhyT+LT6wCBmt9gP2yeH8g+oAAAABHNzaDo= abutt@tiberius.com"
          "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKoZU8AWvPjbgJfQXA3Kl6Ep9PzO6tGdN3GP4BRcTitOAAAABHNzaDo= anthony@abutt.io"
        ];
      };
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      deployPkgs = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        deploySystem:
        import nixpkgs {
          system = deploySystem;
          overlays = [ (import ./overlays/deploy-rs-from-nixpkgs.nix { inherit deploy-rs; }) ];
        }
      );
      opnsenseConfig = import ./hosts/protectli {
        inherit pkgs;
        inherit (user) sshKeys;
        apiKey = "CHANGEME_GENERATE_API_KEY";
        apiSecretHash = "CHANGEME_GENERATE_API_SECRET";
      };
    in
    {
      formatter.${system} = treefmtEval.config.build.wrapper;
      packages.${system} = {
        opnsense-config = opnsenseConfig;
        # Alias so `nix build .#kiosk-sd` works (built as aarch64 via binfmt)
        kiosk-sd = self.nixosConfigurations.kiosk.config.system.build.sdImage;
      };
      checks.${system} = {
        pre-commit-check = pkgs.callPackage ./pre-commit.nix {
          inherit pre-commit-hooks treefmtEval;
        };
      }
      // (deployPkgs.${system}.deploy-rs.lib.deployChecks self.deploy);
      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        packages = self.checks.${system}.pre-commit-check.enabledPackages ++ [
          treefmtEval.config.build.wrapper
          deployPkgs.${system}.deploy-rs.deploy-rs
          pkgs.sops
        ];
        env = {
          CLAUDE_INSTANCE = "nix-config";
          CONTEXT_DOCS_ROOT = "/home/anthony/nix-config/.claude";
        };
      };
      nixosConfigurations =
        let
          themes = import ./themes.nix { inherit pkgs; };

          hosts = {
            tiberius = {
              hardwareModules = [
                nixos-hardware.nixosModules.dell-precision-3490-intel
                nixos-hardware.nixosModules.common-gpu-intel
              ];
              theme = "pokemon-starters";
            };
            atlas = {
              hardwareModules = [ nixos-hardware.nixosModules.framework-16-7040-amd ];
              theme = "pokemon-starters";
            };
            mantra = {
              hardwareModules = [
                nixos-hardware.nixosModules.common-cpu-amd
                nixos-hardware.nixosModules.common-cpu-amd-pstate
                nixos-hardware.nixosModules.common-gpu-amd
                nixos-hardware.nixosModules.common-pc
                nixos-hardware.nixosModules.common-pc-ssd
              ];
              theme = "pokemon-starters";
            };
            lapnix = {
              hardwareModules = [ nixos-hardware.nixosModules.framework-13-7040-amd ];
              theme = "pokemon-starters";
            };
          };
          mkSystem =
            hostname:
            { hardwareModules, theme }:
            let
              themeConfig = themes.${theme};
            in
            nixpkgs.lib.nixosSystem {
              inherit pkgs;
              specialArgs = {
                inherit user inputs hyprland;
              };
              modules = hardwareModules ++ [
                { nixpkgs.hostPlatform = system; }
                ./hosts/${hostname}/configuration.nix
                stylix.nixosModules.stylix
                disko.nixosModules.disko
                sops-nix.nixosModules.sops
                ./modules/stylix
                {
                  modules.themes.theme = themeConfig.scheme;
                  modules.themes.wallpaper = themeConfig.wallpaper;
                  modules.themes.polarity = themeConfig.polarity;
                }
              ];
            };
        in
        (builtins.mapAttrs mkSystem hosts)
        // {
          # Minimal Installation ISO (special case)
          iso = nixpkgs.lib.nixosSystem {
            inherit pkgs;
            specialArgs = {
              inherit user;
            };
            modules = [
              { nixpkgs.hostPlatform = system; }
              ./hosts/iso/configuration.nix
            ];
          };
          rescue = nixpkgs.lib.nixosSystem {
            inherit pkgs;
            modules = [
              { nixpkgs.hostPlatform = system; }
              ./hosts/rescue/configuration.nix
            ];
          };
          # Raspberry Pi 5 kiosk (aarch64, special case — no themes/disko)
          kiosk = inputs.nixos-raspberrypi.lib.nixosSystem {
            specialArgs = inputs // {
              inherit user inputs;
            };
            modules = [
              {
                imports = with inputs.nixos-raspberrypi.nixosModules; [
                  raspberry-pi-5.base
                  raspberry-pi-5.display-vc4
                ];
              }
              disko.nixosModules.disko
              ./hosts/kiosk/disks.nix
              ./hosts/kiosk/configuration.nix
            ];
          };
        };
      homeConfigurations =
        let
          themes = import ./themes.nix { inherit pkgs; };

          hostDefaults = {
            tiberius = "pokemon-starters";
            atlas = "pokemon-starters";
            lapnix = "pokemon-starters";
            mantra = "pokemon-starters";
          };

          mkHome =
            hostname: themeName:
            let
              theme = themes.${themeName};
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit inputs user;
              };
              modules = [
                {
                  home.username = user.username;
                  home.stateVersion = "25.05";
                  home.homeDirectory = "/home/${user.username}";
                }
                ./home/home.nix
                ./hosts/${hostname}/home-overrides.nix
                stylix.homeModules.stylix
                {
                  modules.themes.theme = theme.scheme;
                  modules.themes.wallpaper = theme.wallpaper;
                  modules.themes.polarity = theme.polarity;
                  modules.themes.fastfetchLogo = theme.fastfetchLogo or null;
                  modules.themes.fastfetchLogoType = theme.fastfetchLogoType or null;
                  modules.hyprpaper.wallpaper = builtins.toString theme.wallpaper;
                }
              ];
            };

          # Generate all host x theme combinations
          allConfigs = nixpkgs.lib.listToAttrs (
            builtins.concatLists (
              nixpkgs.lib.mapAttrsToList (
                hostname: defaultTheme:
                let
                  # Default config uses the host's default theme
                  default = {
                    name = "${user.username}@${hostname}";
                    value = mkHome hostname defaultTheme;
                  };
                  # Named variant for every theme
                  variants = nixpkgs.lib.mapAttrsToList (themeName: _: {
                    name = "${user.username}@${hostname}-${themeName}";
                    value = mkHome hostname themeName;
                  }) themes;
                in
                [ default ] ++ variants
              ) hostDefaults
            )
          );
        in
        allConfigs;
      deploy.nodes = {
        mantra = {
          hostname = "mantra";
          profiles.system = {
            user = "root";
            sshUser = user.username;
            path = deployPkgs.x86_64-linux.deploy-rs.lib.activate.nixos self.nixosConfigurations.mantra;
          };
        };
        atlas = {
          hostname = "atlas";
          profiles.system = {
            user = "root";
            sshUser = user.username;
            path = deployPkgs.x86_64-linux.deploy-rs.lib.activate.nixos self.nixosConfigurations.atlas;
          };
        };
        lapnix = {
          hostname = "lapnix";
          profiles.system = {
            user = "root";
            sshUser = user.username;
            path = deployPkgs.x86_64-linux.deploy-rs.lib.activate.nixos self.nixosConfigurations.lapnix;
          };
        };
        kiosk = {
          hostname = "kiosk.local";
          profiles.system = {
            user = "root";
            sshUser = user.username;
            path = deployPkgs.aarch64-linux.deploy-rs.lib.activate.nixos self.nixosConfigurations.kiosk;
          };
        };
      };
    };
}
