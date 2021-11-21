{
  description = "barsoo nixos system";

  # Define system dependencies
  inputs = {
    nixpkgs = {
      # url = "github:NixOS/nixpkgs/nixos-unstable";
      url = "github:NixOS/nixpkgs/master";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: manage secrets
    #agenix = {
    #  url = "github:ryantm/agenix";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  # Define desired systems
  # NOTE: for every new input from above, put a new argument in inputs below
  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      # Define pkgs for ease of usage
      pkgs = import nixpkgs { inherit system; };

      # Utils to automatically create outputs
      flakeLib = import ./lib { inherit nixpkgs; inherit pkgs; };

    in {
      # Actuall systems configurations (per host)
      nixosConfigurations = flakeLib.collectHosts ./hosts {
          modulesPath = ./modules;
          pkgsLocal = self.packages."${system}";
          inherit home-manager;
      };

      # Modules for system configurations
      nixosModules = flakeLib.collectModules ./modules {};

      # Include custom local packages
      # NOTE: Executed by `nix build .#<name>`
      packages."${system}" = flakeLib.collectPackages ./packages { inherit pkgs; };

      # Just a simple development shell with flaked nix
      # NOTE: Used by `nix develop`
      devShell."${system}" = import ./shell.nix { inherit pkgs; };
    };
}
