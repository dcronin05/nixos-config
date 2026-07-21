{ config, pkgs, ... }:

{
  imports = [
    ./cli.nix
    ./desktop.nix
  ];
  
  home.username = "dcronin05";
  home.homeDirectory = "/home/dcronin05";
  home.stateVersion = "24.05";
}
