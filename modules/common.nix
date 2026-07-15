{ config, pkgs, ... }:

{
  # Define a user account.
  users.users.dcronin05 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable sudo
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    btop
    htop
    git
    gh
    zip
    unzip
    tmux
  ];

  # Enable Tailscale
  services.tailscale.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable nix-ld (for VSCode Remote-SSH)
  programs.nix-ld.enable = true;

  # Enable Flakes and the Nix CLI
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
