{
  description = "Cronin NixOS Infrastructure";

  inputs = {
    # Using the rolling unstable release channel
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nvim-config = {
      url = "git+ssh://git@github.com/dcronin05/nvim-config.git";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, sops-nix, home-manager, nvim-config }: {
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
            home-manager.extraSpecialArgs = { inherit nvim-config; };
            home-manager.users.dcronin05 = import ./home/nexus.nix;
          }
        ];
      };
    };

    homeConfigurations = let
      mkHome = hostname: system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit nvim-config; };
        modules = [
          sops-nix.homeManagerModules.sops
          (./home + "/${hostname}.nix")
        ];
      };
    in {
      "dcronin05@laptop" = mkHome "laptop" "x86_64-linux";
      "dcronin05@macbook" = mkHome "macbook" "aarch64-darwin";
    };
  };
}
