{ config, pkgs, ... }:

{
  # 1. Ghostty Terminal Configuration
  xdg.configFile."ghostty/config".text = ''
    theme = Nvim Dark
    
    # Force Ghostty to report as xterm-256color for universal compatibility on remote SSH hosts
    term = xterm-256color
  '';
}
