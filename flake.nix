{
  description = "My personal flake";
  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-color-lsp.url = "github:tonybutt/nixpkgs/color-lsp-init";
    claude-code.url = "github:sadjow/claude-code-nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    hyprland.url = "github:hyprwm/Hyprland";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    treefmt-nix.url = "github:numtide/treefmt-nix";
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
    team-claude-skills.url = "git+ssh://git@github.com/tiberius-grail/team-claude-skills";
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
  };
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://claude-code.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
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
      nur,
      treefmt-nix,
      pre-commit-hooks,
      claude-code,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          nur.overlays.default
          claude-code.overlays.default
        ];
      };
      user = {
        username = "anthony";
        fullName = "Anthony Butt";
        work = {
          email = "abutt@tiberius.com";
          signingKey = "~/.ssh/id_ed25519_sk.pub";
          githubOrg = "tiberius-grail";
        };
        personal = {
          email = "anthony@abutt.io";
          signingKey = "~/.ssh/id_ed25519_personal.pub";
          githubUsername = "tonybutt";
        };
      };
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      opnsenseConfig = import ./hosts/protectli {
        inherit pkgs;
        sshKeys = [
          "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO9ZH1VvOc2+1tAkzQzNwhyT+LT6wCBmt9gP2yeH8g+oAAAABHNzaDo= abutt@tiberius.com"
          "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKoZU8AWvPjbgJfQXA3Kl6Ep9PzO6tGdN3GP4BRcTitOAAAABHNzaDo= anthony@abutt.io"
        ];
        apiKey = "CHANGEME_GENERATE_API_KEY";
        apiSecretHash = "CHANGEME_GENERATE_API_SECRET";
      };
    in
    {
      homeModules = {
        claude-cognitive = import ./modules/hm/ai/claude-cognitive.nix;
      };
      formatter.${system} = treefmtEval.config.build.wrapper;
      packages.${system}.opnsense-config = opnsenseConfig;
      checks.${system} = {
        pre-commit-check = pkgs.callPackage ./pre-commit.nix {
          inherit pre-commit-hooks treefmtEval;
        };
      }
      // (deploy-rs.lib.${system}.deployChecks self.deploy);
      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        packages = [
          (self.checks.${system}.pre-commit-check.enabledPackages)
          treefmtEval.config.build.wrapper
          deploy-rs.packages.${system}.default
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
              theme = "final-fantasy";
            };
            atlas = {
              hardwareModules = [ nixos-hardware.nixosModules.framework-16-7040-amd ];
              theme = "final-fantasy";
            };
            mantra = {
              hardwareModules = [
                nixos-hardware.nixosModules.common-cpu-amd
                nixos-hardware.nixosModules.common-cpu-amd-pstate
                nixos-hardware.nixosModules.common-gpu-amd
                nixos-hardware.nixosModules.common-pc
                nixos-hardware.nixosModules.common-pc-ssd
              ];
              theme = "final-fantasy";
            };
            lapnix = {
              hardwareModules = [ nixos-hardware.nixosModules.framework-13-7040-amd ];
              theme = "final-fantasy";
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
        };
      homeConfigurations =
        let
          themes = import ./themes.nix { inherit pkgs; };

          hostDefaults = {
            tiberius = "final-fantasy";
            atlas = "ugrain";
            lapnix = "final-fantasy";
            mantra = "final-fantasy";
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
          allConfigs = builtins.foldl' (acc: { name, value }: acc // { ${name} = value; }) { } (
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
      deploy.nodes.mantra = {
        hostname = "mantra";
        profiles.system = {
          user = "root";
          sshUser = user.username;
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mantra;
        };
      };
    };
}
