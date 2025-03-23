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
  };
  nixConfig = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  outputs =
    {
      nixpkgs,
      stylix,
      home-manager,
      hyprland,
      disko,
      twofctl,
      nixos-hardware,
      nixcord,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ twofctl.overlays.default ];
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
          inherit pkgs system;
          specialArgs = {
            inherit user hyprland;
          };
          modules = [
            ./hosts/mantra/configuration.nix
            ./style
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
            ./style
            stylix.nixosModules.stylix
            disko.nixosModules.disko
          ];
        };
        # Minimal Installation ISO.
        iso = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          modules = [
            ./hosts/iso/configuration.nix
          ];
        };
      };
      homeConfigurations = {
        "${user.name}" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit user;
          };
          modules = [
            ./home/home.nix
            ./style
            stylix.homeManagerModules.stylix
            nixcord.homeManagerModules.nixcord
          ];
        };
      };
    };
}
