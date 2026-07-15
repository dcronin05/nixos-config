{
  description = "Cronin NixOS Infrastructure";

  inputs = {
    # Using the stable 24.05 release channel
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      nexus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/common.nix
          ./hosts/nexus.nix
        ];
      };
    };
  };
}
