{
  description = "Cronin NixOS Infrastructure";

  inputs = {
    # Using the rolling unstable release channel
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, sops-nix, home-manager }: {
    nixosConfigurations = {
      nexus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          ./modules/common.nix
          ./hosts/nexus.nix
          { 
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
            home-manager.users.dcronin05 = import ./home/nexus.nix;
          }
        ];
      };
    };

    homeConfigurations = let
      mkHome = hostname: system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          sops-nix.homeManagerModules.sops
          (./home + "/${hostname}.nix")
        ];
      };
    in {
      "dcronin05@laptop" = mkHome "laptop" "x86_64-linux";
      "dcronin05@macbook" = mkHome "macos" "aarch64-darwin";
      "dcronin05@M4-Mini" = mkHome "macos" "aarch64-darwin";
    };
  };
}
