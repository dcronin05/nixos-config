# WezTerm, via the wezterm-config flake input (github.com/dcronin05/wezterm-config).
{ config, pkgs, wezterm-config, ... }:

{
  xdg.configFile."wezterm".source = wezterm-config;
}
