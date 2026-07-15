{ config, pkgs, ... }:

{
  # Define a user account.
  users.users.dcronin05 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable sudo
    shell = pkgs.zsh;
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
    zellij
    sops
  ];

  # Enable Tailscale
  services.tailscale.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable nix-ld (for VSCode Remote-SSH)
  programs.nix-ld.enable = true;

  # Enable Flakes and the Nix CLI
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Zsh and Starship prompt
  programs.zsh.enable = true;
  programs.starship.enable = true;

  # SOPS Secrets Configuration
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.keyFile = "/home/dcronin05/.config/sops/age/keys.txt";

  sops.secrets.github_token = {};
  sops.secrets.tailscale_state = {};

  # Restore Tailscale state on first boot
  systemd.services.tailscaled.preStart = ''
    mkdir -p /var/lib/tailscale
    if [ ! -f /var/lib/tailscale/tailscaled.state ]; then
      cp ${config.sops.secrets.tailscale_state.path} /var/lib/tailscale/tailscaled.state
      chmod 600 /var/lib/tailscale/tailscaled.state
    fi
  '';
}
