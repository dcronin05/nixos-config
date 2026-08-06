# ==============================================================================
# LAPTOP (SPECIFIC DEVICE PROFILE - CACHYOS)
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
#
# This profile is specifically designed for the device named `laptop`, which is a 
# CachyOS graphical Linux device managed purely by standalone Home Manager.
# It imports `base.nix` to guarantee identical CLI tools.
# ==============================================================================

{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ./desktop.nix
    ./wezterm.nix
    ./standalone-daemons.nix
    (import ./authorized-keys.nix { })
  ];
}
