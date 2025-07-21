{
  description = "barsoo nixos system";

  # Define system dependencies
  inputs = {
    nixpkgs-master = {
      url = "github:NixOS/nixpkgs/master";
    };

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/24.05";
    };

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    helix = {
      url = "github:helix-editor/helix/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    musnix = { 
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # TODO: manage secrets
    #agenix = {
    #  url = "github:ryantm/agenix";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  # Define desired systems
  # NOTE: for every new input from above, put a new argument in inputs below
  outputs =
    inputs@{ self
    , nixpkgs-master
    , nixpkgs-stable
    , nixpkgs-unstable
    , home-manager
    , musnix
    , helix
    , ...
    }:
    let
      system = "x86_64-linux";
      config = { allowUnfree = true; };

      helix-pkgs = helix.packages."${system}";

      # Define pkgs for ease of usage
      pkgsRepo = rec {
      	helix = helix-pkgs; 
        master = import nixpkgs-master { inherit system config; };
        stable = import nixpkgs-stable { inherit system config; };
        unstable = import nixpkgs-unstable { inherit system config; };
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
        inherit localLib home-manager;
        extraModules = [
          home-manager.nixosModules.default
          musnix.nixosModules.default
        ];
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
