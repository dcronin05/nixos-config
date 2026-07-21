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
          { home-manager.users.dcronin05 = import ./home/cli.nix; }
        ];
      };
    };

    homeConfigurations = {
      "dcronin05@laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home/laptop.nix
        ];
      };
    };
  };
}
