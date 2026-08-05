# ==============================================================================
# MACOS HOME MANAGER PROFILE
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
#
# This profile is specifically designed for Apple Silicon / macOS devices.
# It imports `base.nix` to get the exact same CLI environment (Starship, Zellij, 
# Neovim, packages) as the Linux servers, ensuring 100% parity.
# 
# Additionally, because this is a graphical macOS device, it imports 
# `wezterm.nix` to configure the terminal emulator itself.
# ==============================================================================

{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ./wezterm.nix
    (import ./authorized-keys.nix { })
  ];

  # Fix non-interactive SSH PATH and locale for Mosh/ET (Moshi app support)
  home.sessionPath = [
    "/opt/homebrew/bin"
  ];
  home.sessionVariables = {
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
  };

  # NOTE FOR AGENTS: Use `initContent` instead of `initExtra` in this setup
  # to avoid home-manager deprecation warnings regarding proper context.
  programs.zsh.initContent = ''
    [[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
    export PATH="/Users/dcronin05/.antigravity/antigravity/bin:$PATH"
    export PATH="/Users/dcronin05/.antigravity-ide/antigravity-ide/bin:$PATH"
    export CRONIN_ENDPOINT="https://agy.cronin.one/webhook/stream"
    export CRONIN_TOKEN="7923263afb1524f8f628924c6cabc19c88b175422d7559d19dfc1c6648a9766e"
    export PATH="/Users/dcronin05/.local/bin:$PATH"
    
    # Generated for envman. Do not edit.
    [ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
  '';

  programs.zsh.shellAliases = {
    tdocker = "ssh -t dcron@tower docker";
    ls = "lsd";
  };
}
