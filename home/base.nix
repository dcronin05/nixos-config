{ config, pkgs, lib, ... }:

# ==============================================================================
# BASE HOME MANAGER CONFIGURATION (THE UNIVERSAL CORE)
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
# 
# This file is the absolute foundation of the user's environment. 
# It abstracts away all the boilerplate (username, homeDirectory, stateVersion)
# and imports the core CLI environment (cli.nix) and editor (neovim.nix).
#
# By centralizing this here, ALL profiles (macOS, Linux GUI, Linux Headless)
# can simply import this one file to guarantee 100% parity across machines.
# 
# Notice the `pkgs.stdenv.isDarwin` check below? That is why this file is so 
# powerful. It dynamically resolves the home directory path depending on 
# whether it's compiling for a Mac or a Linux server, making this config 
# perfectly cross-platform.
# ==============================================================================

{
  imports = [
    ./cli.nix
    ./neovim.nix
  ];

  home = {
    username = "dcronin05";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/dcronin05" else "/home/dcronin05";
    stateVersion = "24.05";
  };
}
