# WezTerm, from the monorepo dotfiles/wezterm/ directory (see README.md's
# "Monorepo Dotfiles" section for why this isn't a separate flake input).
#
# IMPORTANT: This should ONLY be imported by graphical profiles (macOS, CachyOS).
# NEVER import this into `base.nix` or a headless profile (`nexus`, `headless.nix`), 
# because compiling WezTerm on a headless Linux server will drag in a massive 
# dependency tree of Wayland/X11 display drivers.
{ config, pkgs, ... }:

{
  xdg.configFile."wezterm".source = ../dotfiles/wezterm;
}
