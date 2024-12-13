{
  description = "My personal flake";
  nixConfig = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };
  inputs = {
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

  outputs =
    {
      self,
      nixpkgs,
      stylix,
      home-manager,
      hyprland,
      disko,
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
          specialArgs = {
            pkgs = nixpkgsCfg;
            inherit user system hyprland;
          };
          modules = [
            ./hosts/mantra/configuration.nix
            stylix.nixosModules.stylix
            disko.nixosModules.disko
          ];
        };
        lapnix = nixpkgs.lib.nixosSystem {
          specialArgs = {
            pkgs = nixpkgsCfg;
            inherit user system hyprland;
          };
          modules = [
            ./hosts/lapnix/configuration.nix
            stylix.nixosModules.stylix
            disko.nixosModules.disko
          ];
        };
        # Minimal Installation ISO.
        iso = nixpkgs.lib.nixosSystem {
          specialArgs = {
            pkgs = nixpkgsCfg;
            inherit system;
          };
          modules = [
            ./hosts/iso/configuration.nix
          ];
        };
      };
      homeConfigurations = {
        anthony = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgsCfg;
          extraSpecialArgs = {
            inherit user system hyprland;
          };
          modules = [
            ./home/home.nix
            stylix.homeManagerModules.stylix
          ];
        };
      };
    };
}
