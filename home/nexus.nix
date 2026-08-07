# ==============================================================================
# NEXUS (SPECIFIC DEVICE PROFILE)
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
#
# This profile is specifically designed for the device named `nexus`, which is a 
# headless NixOS server.
# It imports `base.nix` to get the exact same CLI environment (Starship, Zellij, 
# Neovim, packages) as the MacBooks, ensuring 100% parity across devices.
# 
# Notice that it explicitly DOES NOT import `wezterm.nix` or any GUI apps.
# This is by design, to prevent compiling Wayland/X11 dependencies on a server.
#
# It also imports `mail-hub.nix`, which no other profile does. nexus is the one
# machine that downloads mail from the providers and mirrors it for the fleet, so
# it is the only machine that holds provider credentials and runs sync timers.
# See `AI Knowledge Base/mail_sync_hub_plan.md` for the full design.
# ==============================================================================

{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ./mail-hub.nix
  ];
}
