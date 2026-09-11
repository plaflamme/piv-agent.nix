{
  description = "piv-agent home-manager module";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.home-manager.flakeModules.home-manager
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        {
          self',
          pkgs,
          ...
        }:
        {
          packages = {
            piv-agent = pkgs.callPackage ./packages/piv-agent.nix { };
            default = self'.packages.piv-agent;
          };

          checks = import ./tests {
            inherit pkgs;
            home-manager = inputs.home-manager;
            piv-agent = self.homeModules.piv-agent;
          };

          formatter = pkgs.nixfmt-tree;
        };
      flake = {
        overlays.default = final: prev: {
          piv-agent = final.callPackage ./packages/piv-agent.nix { };
        };
        homeModules = {
          piv-agent = { lib, pkgs, ... }: {
            imports = [ ./homeModules/default.nix ];
            services.piv-agent.package =
              lib.mkDefault
                self.packages.${pkgs.stdenv.hostPlatform.system}.piv-agent;
          };
          default = self.packages.piv-agent;
        };
      };
    };
}
