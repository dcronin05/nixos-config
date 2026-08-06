# ==============================================================================
# FLAKE ENTRYPOINT (THE MASTER ARCHITECTURE)
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
# 
# This flake uses a strict 3-tier modular architecture intentionally designed to
# support NixOS Headless Servers, macOS Laptops, headless/WSL Linux boxes, and
# future Graphical NixOS machines.
#
# 1. nixosConfigurations:
#    - Defines full OS-level builds (e.g. `nexus`).
#    - Uses `modules/common.nix` for OS-level settings (SSH, Tailscale, Sudo).
#    - NEVER puts user CLI packages in `common.nix`.
#
# 2. homeConfigurations:
#    - Defines standalone Home Manager setups (e.g. `macbook`, `laptop`, `forge`).
#    - Every profile (whether invoked by NixOS or standalone HM) MUST import
#      `home/base.nix` to guarantee 100% parity of the CLI environment.
#
# ../lib/trusted-keys.nix holds the cross-device SSH trust mesh's canonical
# key data (see docs/architecture.md) -- pure data, not a module, imported by
# both nixosConfigurations and homeConfigurations sides.
#
# By keeping Home Manager configurations strictly separated from OS-level
# configurations, this codebase remains extremely DRY and infinitely extensible.
# ==============================================================================
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
        specialArgs = { hostColor = "#fd971f"; }; # Orange for Nexus
        modules = [
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          ./modules/common.nix
          ./hosts/nexus.nix
          { 
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { hostColor = "#fd971f"; };
            home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
            home-manager.users.dcronin05 = import ./home/nexus.nix;
          }
        ];
      };
    };

    homeConfigurations = let
      mkHome = hostname: hostColor: system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit hostColor; };
        modules = [
          sops-nix.homeManagerModules.sops
          (./home + "/${hostname}.nix")
        ];
      };
    in {
      "dcronin05@laptop" = mkHome "laptop" "#66d9ef" "x86_64-linux";  # Blue
      "dcronin05@macbook" = mkHome "macos" "#a6e22e" "aarch64-darwin"; # Green
      "dcronin05@M4-Mini" = mkHome "macos" "#e6db74" "aarch64-darwin"; # Yellow
      "dcronin05@forge" = mkHome "headless" "#f92672" "x86_64-linux";  # Red
      "dcronin05@debian-vm" = mkHome "headless" "#ae81ff" "x86_64-linux"; # Purple
    };
  };
}
