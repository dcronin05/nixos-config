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

  # This option defines the first version of NixOS you have installed on this particular machine
  system.stateVersion = "24.05";
}
