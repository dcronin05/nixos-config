# WezTerm, from the monorepo dotfiles/wezterm/ directory (see README.md's
# "Monorepo Dotfiles" section for why this isn't a separate flake input).
{ config, pkgs, ... }:

{
  xdg.configFile."wezterm".source = ../dotfiles/wezterm;
}
