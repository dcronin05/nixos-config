{
  description = "Cronin NixOS Infrastructure";

  inputs = {
    # Using the stable 24.05 release channel
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, sops-nix }: {
    nixosConfigurations = {
      nexus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          sops-nix.nixosModules.sops
          ./modules/common.nix
          ./hosts/nexus.nix
        ];
      };
    };
  };
}
