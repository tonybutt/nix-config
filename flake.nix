{
  description = "My personal flake";
  inputs = {
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
  };
    nixConfig = {
      extra-substituters = ["https://hyprland.cachix.org"];
      extra-trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
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
      ...
    }:
    let
      system = "x86_64-linux";
      nixpkgsCfg = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      user = {
        name = "anthony";
        email = "anthony@abutt.io";
        signingkey = "0xF56C1FE0C44B03BE";
      };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
      nixosConfigurations = {
        mantra = nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = nixpkgsCfg;
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
          inherit system;
          pkgs = nixpkgsCfg;

          specialArgs = {
            inherit user hyprland;
          };
          modules = [
            nixos-hardware.nixosModules.framework-13-7040-amd
            ./hosts/lapnix/configuration.nix
            stylix.nixosModules.stylix
            disko.nixosModules.disko
          ];
        };
        # Minimal Installation ISO.
        iso = nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = nixpkgsCfg;
          modules = [
            ./hosts/iso/configuration.nix
          ];
        };
      };
      homeConfigurations = {
        anthony = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgsCfg;
          extraSpecialArgs = {
            inherit user hyprland;
          };
          modules = [
            ./home/home.nix
            stylix.homeManagerModules.stylix
          ];
        };
      };
    };
}
