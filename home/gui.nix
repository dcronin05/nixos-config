# ==============================================================================
# GRAPHICAL NIXOS DESKTOP PROFILE
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
#
# This profile is specifically designed for full graphical Linux desktop setups.
# It imports `base.nix` to get the universal CLI environment (100% parity).
# 
# It also imports `wezterm.nix` and serves as the injection point for future 
# desktop Linux apps (like browsers, Discord, VSCode) without bloating headless servers.
# ==============================================================================

{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ./wezterm.nix
    # You can add future linux graphical apps here like ./discord.nix, ./vscode.nix
  ];
}
