# Host dependencies for this Neovim config, for import into a home-manager
# module, e.g.:
#
#   home.packages = import "${inputs.nvim-config}/nix/packages.nix" { inherit pkgs; };
#
# Mirrors the non-Nix path in ../bootstrap.sh — keep the two in sync when a
# plugin adds a new external tool requirement.
{ pkgs }:

with pkgs; [
  neovim
  gcc
  ripgrep
  fd
  lazygit
  nodejs
  tree-sitter
  markdownlint-cli2
]

