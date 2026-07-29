{ config, pkgs, ... }:

{
  imports = [
    ./cli.nix
    ./neovim.nix
  ];

  # This is the home manager profile for headless non-NixOS Linux (like WSL or Debian)
  # home.username = "dcronin05";
  # home.homeDirectory = "/home/dcronin05";
  # home.stateVersion = "24.05";
}
