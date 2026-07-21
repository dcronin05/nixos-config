{ config, pkgs, ... }:

{
  home.stateVersion = "24.05";
  
  # User-level terminal configurations
  programs.starship.enable = true;
  programs.zellij.enable = true;
  programs.zsh.enable = true;
  
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "dcronin05";
        email = "daniel@dcron.in";
      };
      safe = {
        directory = "/home/dcronin05";
      };
    };
  };
  
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        extraOptions = {
          SetEnv = "TERM=xterm-256color";
        };
      };
      "debian-vm" = {
        hostname = "100.125.115.8";
        user = "dcronin05";
      };
      "tower" = {
        hostname = "100.79.77.74";
        user = "dcron";
      };
      "macmini" = {
        hostname = "100.117.198.24";
        user = "dcronin05";
      };
      "macbook" = {
        hostname = "100.76.154.2";
        user = "dcronin05";
      };
      "gpantz" = {
        hostname = "gpantz.castor.usbx.me";
        user = "gpantz";
      };
      "pxe" = {
        hostname = "dcron.in";
        user = "root";
        port = 2206;
      };
      "wsl" = {
        hostname = "100.79.77.74";
        user = "dcronin05";
        port = 2299;
      };
      "vps" = {
        hostname = "162.212.157.166";
        user = "dcronin05";
      };
      "nix" = {
        hostname = "192.168.1.170";
        user = "dcronin05";
      };
    };
  };
}
