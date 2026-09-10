{
  description = "piv-agent package and overlay";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
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
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          packages.piv-agent = pkgs.callPackage ./packages/piv-agent.nix { };
          packages.default = self'.packages.piv-agent;
        };
      flake = {
        overlays.default = final: prev: {
          piv-agent = final.callPackage ./packages/piv-agent.nix { };
        };
        homeModules = rec {
          piv-agent = import ./home/default.nix;
          default = piv-agent;
        };
      };
    };
}
