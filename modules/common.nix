{ config, pkgs, ... }:

{
  # Define a user account.
  users.users.dcronin05 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable sudo
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILXLAoRT/mL0V1seGltPF+y2oC4fma96SZz40NI9NGjp debian-vm"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEe6oeFzP00bx7VSsAf+qxXff8NKhb9DrqqPly0vxdN m4-mini"
    ];
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
    sops
    tree
  ];

  environment.variables.FLAKE = "${config.users.users.dcronin05.home}/nixos-config";

  # Enable Tailscale
  services.tailscale.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable nix-ld (for VSCode Remote-SSH)
  programs.nix-ld.enable = true;

  # Enable Flakes and the Nix CLI
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Zsh globally (required for Home Manager zsh integration)
  programs.zsh.enable = true;

  # SOPS Secrets Configuration
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.keyFile = "${config.users.users.dcronin05.home}/.config/sops/age/keys.txt";

  sops.secrets.github_token = {};
  sops.secrets.tailscale_state = {};
  sops.secrets.ssh_private_key = {
    owner = "dcronin05";
    path = "${config.users.users.dcronin05.home}/.ssh/id_ed25519";
    mode = "0600";
  };

  # Restore Tailscale state on first boot
  systemd.services.tailscaled.preStart = ''
    mkdir -p /var/lib/tailscale
    if [ ! -f /var/lib/tailscale/tailscaled.state ]; then
      cp ${config.sops.secrets.tailscale_state.path} /var/lib/tailscale/tailscaled.state
      chmod 600 /var/lib/tailscale/tailscaled.state
    fi
  '';

  # Home Manager Configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup"; # Silently backup conflicting files instead of throwing clobber errors
}
