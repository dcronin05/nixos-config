# ==============================================================================
# NIXOS SYSTEM MODULE (THE OS CORE)
# ==============================================================================
# Please consider the macOS/HomeManager split before adding CLI tools here.
#
# This file is strictly for OS-level daemon configuration for NixOS hosts.
# It handles networking, SSH, Tailscale, Sudo rules, and Nix config.
#
# Why no user packages?
# Because `common.nix` is only imported by NixOS machines. macOS devices running
# standalone Home Manager completely ignore this file. If you put `wget` or `htop`
# in `environment.systemPackages`, the macOS devices won't get them!
# 
# ALL user-facing CLI tools MUST go into `home/cli.nix` under `home.packages` 
# so that they are universally installed across all operating systems.
# ==============================================================================
{ config, pkgs, ... }:

let
  # Every Nix-managed device's identity (see lib/trusted-keys.nix). nexus
  # doesn't need to trust itself, and debian-vm isn't part of this mesh yet
  # (kept as its own separate, hand-added entry below) since it's not a
  # Nix-managed device.
  meshKeys = import ../lib/trusted-keys.nix;
  meshTrust = map (name: meshKeys.${name}) (builtins.attrNames (removeAttrs meshKeys [ "nexus" ]));
in

{
  # Define a user account.
  users.users.dcronin05 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable sudo
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = meshTrust ++ [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILXLAoRT/mL0V1seGltPF+y2oC4fma96SZz40NI9NGjp debian-vm"
    ];
  };


  environment.variables.FLAKE = "${config.users.users.dcronin05.home}/nixos-config";

  # Enable Tailscale
  services.tailscale.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable Moshi resilient connection backends (Firewall & Daemons)
  programs.mosh.enable = true;
  services.eternal-terminal.enable = true;

  # Enable nix-ld (for VSCode Remote-SSH)
  programs.nix-ld.enable = true;

  # Enable Flakes and the Nix CLI
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Zsh globally (required for Home Manager zsh integration)
  programs.zsh.enable = true;

  # Allow nixos-rebuild without a password (scoped to just that command, not
  # blanket sudo). Uses the stable system-profile symlink, not a /nix/store
  # path, so it survives package updates.
  security.sudo.extraRules = [
    {
      users = [ "dcronin05" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  
  # SOPS Secrets Configuration
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.keyFile = "${config.users.users.dcronin05.home}/.config/sops/age/keys.txt";

  sops.secrets.ssh_private_key = {
    owner = "dcronin05";
    path = "${config.users.users.dcronin05.home}/.ssh/id_ed25519";
    mode = "0600";
  };



  # Home Manager Configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup"; # Silently backup conflicting files instead of throwing clobber errors
}
