# Neovim, via the nvim-config flake input (github.com/dcronin05/nvim-config).
# Import this alongside cli.nix on any host that should get the editor —
# it's kept as its own layer (not folded into cli.nix) so a minimal/headless
# host can opt out without touching the rest of the CLI setup.
{ config, pkgs, ... }:

{
  xdg.configFile."nvim".source = ../dotfiles/nvim;
  home.packages = import ../dotfiles/nvim/nix/packages.nix { inherit pkgs; };
}
