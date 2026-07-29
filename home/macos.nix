{ config, pkgs, ... }:

{
  imports = [
    ./cli.nix
    ./neovim.nix
    ./wezterm.nix
  ];
  
  home.username = "dcronin05";
  home.homeDirectory = "/Users/dcronin05";
  home.stateVersion = "24.05";

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
