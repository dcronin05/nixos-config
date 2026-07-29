{ config, pkgs, ... }:

{
  imports = [
    ./cli.nix
    ./neovim.nix
    ./wezterm.nix
    # You can add future linux graphical apps here like ./discord.nix, ./vscode.nix
  ];

  # This is the home manager profile for a full graphical Linux machine.
  # home.username = "dcronin05";
  # home.homeDirectory = "/home/dcronin05";
  # home.stateVersion = "24.05";
}
