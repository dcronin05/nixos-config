# Neovim, from the monorepo dotfiles/nvim/ directory (originally its own
# repo, github.com/dcronin05/nvim-config, absorbed here to avoid managing a
# separate flake.lock -- see README.md's "Monorepo Dotfiles" section).
# Import this alongside cli.nix on any host that should get the editor —
# it's kept as its own layer (not folded into cli.nix) so a minimal/headless
# host can opt out without touching the rest of the CLI setup.
{ config, pkgs, ... }:

{
  xdg.configFile."nvim".source = ../dotfiles/nvim;
  home.packages = import ../dotfiles/nvim/nix/packages.nix { inherit pkgs; };
}
