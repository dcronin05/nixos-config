# WezTerm, via the wezterm-config flake input (github.com/dcronin05/wezterm-config).
{ config, pkgs, ... }:

{
  xdg.configFile."wezterm".source = ../dotfiles/wezterm;
}
