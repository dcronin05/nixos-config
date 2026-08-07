{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nexus"; # Define your hostname.

  # Enable Hyper-V Guest Services
  virtualisation.hypervGuest.enable = true;

  # Keep this user's systemd instance alive without an active login session.
  #
  # Required by the mail hub (see home/mail-hub.nix). Mail sync is inherently
  # user-scoped -- the user's Maildir, the user's credentials, the user's
  # accounts.email declarations -- so it runs as a systemd USER timer. But a user
  # manager is torn down when the last session ends, which on a headless server
  # means the timer only fires while someone happens to be SSH'd in, and any sync
  # in flight is killed on logout.
  #
  # Set here rather than in modules/common.nix because only the hub needs it;
  # common.nix is for what EVERY NixOS host requires.
  users.users.dcronin05.linger = true;

  sops.secrets.tailscale_state = {};

  # Restore Tailscale state on first boot
  systemd.services.tailscaled.preStart = ''
    mkdir -p /var/lib/tailscale
    if [ ! -f /var/lib/tailscale/tailscaled.state ]; then
      cp ${config.sops.secrets.tailscale_state.path} /var/lib/tailscale/tailscaled.state
      chmod 600 /var/lib/tailscale/tailscaled.state
    fi
  '';

  # This option defines the first version of NixOS you have installed on this particular machine
  system.stateVersion = "24.05";
}
