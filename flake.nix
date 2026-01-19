{
  description = "My personal flake";
  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-color-lsp.url = "github:tonybutt/nixpkgs/color-lsp-init";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
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
  };
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://cosmic.cachix.org/"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
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
      nixos-hardware,
      nur,
      treefmt-nix,
      pre-commit-hooks,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          nur.overlays.default
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
    in
    {
      homeModules = {
        claude-cognitive = import ./modules/hm/ai/claude-cognitive.nix;
      };
      formatter.${system} = treefmtEval.config.build.wrapper;
      checks.${system} = {
        pre-commit-check = pkgs.callPackage ./pre-commit.nix {
          inherit pre-commit-hooks treefmtEval;
        };
      };
      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        packages = [
          (self.checks.${system}.pre-commit-check.enabledPackages)
          treefmtEval.config.build.wrapper
        ];
        env = {
          CLAUDE_INSTANCE = "nix-config";
          CONTEXT_DOCS_ROOT = "/home/anthony/nix-config/.claude";
        };
      };
      nixosConfigurations =
        let
          hosts = {
            tiberius = {
              hardwareModules = [
                nixos-hardware.nixosModules.dell-precision-3490-intel
                nixos-hardware.nixosModules.common-gpu-intel
              ];
            };
            atlas = {
              hardwareModules = [ nixos-hardware.nixosModules.framework-16-7040-amd ];
            };
            mantra = {
              hardwareModules = [ ];
            };
            lapnix = {
              hardwareModules = [ nixos-hardware.nixosModules.framework-13-7040-amd ];
            };
          };
          mkSystem =
            hostname:
            { hardwareModules }:
            nixpkgs.lib.nixosSystem {
              inherit pkgs system;
              specialArgs = {
                inherit user inputs hyprland;
              };
              modules = hardwareModules ++ [
                ./hosts/${hostname}/configuration.nix
                stylix.nixosModules.stylix
                disko.nixosModules.disko
              ];
            };
        in
        (builtins.mapAttrs mkSystem hosts)
        // {
          # Minimal Installation ISO (special case)
          iso = nixpkgs.lib.nixosSystem {
            inherit pkgs system;
            specialArgs = {
              inherit user;
            };
            modules = [ ./hosts/iso/configuration.nix ];
          };
        };
      homeConfigurations =
        let
          mkHome =
            hostname:
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
              ];
            };
        in
        {
          "${user.username}" = mkHome "tiberius"; # default
          "${user.username}@lapnix" = mkHome "lapnix";
          "${user.username}@atlas" = mkHome "atlas";
          "${user.username}@mantra" = mkHome "mantra";
        };
    };
}
