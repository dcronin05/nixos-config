# ==============================================================================
# HEADLESS LINUX HOME MANAGER PROFILE (WSL / DEBIAN / ETC)
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
#
# This profile is specifically designed for non-NixOS headless environments.
# (For example, Ubuntu running under WSL or a standalone Debian server where you 
# are only using Nix package manager).
#
# It imports `base.nix` to get the exact same CLI environment as everything else.
# It explicitly avoids graphical dependencies like WezTerm.
# ==============================================================================

{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
  ];
}
