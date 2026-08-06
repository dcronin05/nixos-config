# Neovim, from the monorepo dotfiles/nvim/ directory (originally its own
# repo, github.com/dcronin05/nvim-config, absorbed here to avoid managing a
# separate flake.lock -- see README.md's "Monorepo Dotfiles" section).
# 
# While this module is extracted into its own file to keep `cli.nix` from 
# becoming bloated, it is imported universally by `base.nix` so that every 
# single machine (macOS, NixOS, WSL) gets the exact same Neovim environment.
{ config, pkgs, ... }:

{
  xdg.configFile."nvim".source = ../dotfiles/nvim;
  home.packages = import ../dotfiles/nvim/nix/packages.nix { inherit pkgs; };
}
