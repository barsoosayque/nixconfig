{
  description = "barsoo nixos system";

  # Define system dependencies
  inputs = {
    nixpkgs-master = {
      url = "github:NixOS/nixpkgs/master";
    };

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/21.11";
    };

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    nixpkgs-staging = {
      url = "github:NixOS/nixpkgs/staging";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-master";
    };

    # TODO: manage secrets
    #agenix = {
    #  url = "github:ryantm/agenix";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  # Define desired systems
  # NOTE: for every new input from above, put a new argument in inputs below
  outputs = inputs@{ self, nixpkgs-master, nixpkgs-stable, nixpkgs-unstable, nixpkgs-staging, home-manager, ... }:
    let
      system = "x86_64-linux";

      # Define pkgs for ease of usage
      pkgsRepo = rec {
        stable = import nixpkgs-stable { inherit system; };
        unstable = import nixpkgs-unstable { inherit system; };
        master = import nixpkgs-master { inherit system; };
        staging = import nixpkgs-staging { inherit system; };
        local = self.packages."${system}";
      };

      nixpkgs = nixpkgs-unstable;
      pkgs = pkgsRepo.unstable;

      # Utils to automatically create outputs
      localLib = import ./lib {
        inherit pkgsRepo nixpkgs pkgs;
      };
    in
    {
      # Actuall systems configurations (per host)
      nixosConfigurations = localLib.flakeUtils.collectHosts ./hosts {
        inherit home-manager localLib;
        modulesPath = ./modules;
      };

      # Modules for system configurations
      nixosModules = localLib.flakeUtils.collectModules ./modules { };

      # Include custom local packages
      # NOTE: Executed by `nix build .#<name>`
      packages."${system}" = localLib.flakeUtils.collectPackages ./packages { inherit pkgs; };

      # Just a simple development shell with flaked nix
      # NOTE: Used by `nix develop`
      devShell."${system}" = import ./shell.nix { inherit pkgs; };
    };
}
