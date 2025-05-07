{
  description = "My personal flake";
  inputs = {
    twofctl = {
      type = "gitlab";
      host = "code.il2.gamewarden.io";
      owner = "gamewarden%2Fplatform";
      repo = "2fctl";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "nixpkgs/nixos-unstable";
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
    nixcord.url = "github:kaylorben/nixcord";
    secondfront.url = "github:tonybutt/modules";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    nur.url = "github:nix-community/NUR";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
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
      twofctl,
      nixos-hardware,
      nixcord,
      secondfront,
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
          twofctl.overlays.default
          nur.overlays.default
        ];
      };
      user = {
        name = "anthony";
        fullName = "Anthony Butt";
        email = "anthony.butt@secondfront.com";
        signingkey = "0xF56C1FE0C44B03BE";
      };
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    {
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
      };
      nixosConfigurations = {
        nixtop = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inherit user inputs hyprland;
          };
          modules = [
            nixos-hardware.nixosModules.dell-xps-15-9530-nvidia
            ./hosts/nixtop/configuration.nix
            stylix.nixosModules.stylix
            disko.nixosModules.disko
            # nixos-cosmic.nixosModules.default
            secondfront.nixosModules.secondfront
          ];
        };
        mantra = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inherit user hyprland;
          };
          modules = [
            ./hosts/mantra/configuration.nix
            stylix.nixosModules.stylix
            disko.nixosModules.disko
          ];
        };
        lapnix = nixpkgs.lib.nixosSystem {
          inherit pkgs system;

          specialArgs = {
            inherit user hyprland;
          };
          modules = [
            nixos-hardware.nixosModules.framework-13-7040-amd
            ./hosts/lapnix/configuration.nix
            stylix.nixosModules.stylix
            disko.nixosModules.disko
            secondfront.nixosModules.secondfront
          ];
        };
        # Minimal Installation ISO.
        iso = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inherit user;
          };

          modules = [
            ./hosts/iso/configuration.nix
          ];
        };
      };
      homeConfigurations = {
        "${user.name}" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs user;
          };
          modules = [
            # ./hosts/nixtop/monitors.nix
            ./home/home.nix
            stylix.homeManagerModules.stylix
            nixcord.homeModules.nixcord
            secondfront.homeManagerModules.secondfront
          ];
        };
        "${user.name}@lapnix" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs user;
          };
          modules = [
            ./hosts/lapnix/home-overrides.nix
            ./home/home.nix
            stylix.homeManagerModules.stylix
            nixcord.homeManagerModules.nixcord
            secondfront.homeManagerModules.secondfront
          ];
        };
      };
    };
}
