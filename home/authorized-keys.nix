# Reusable authorized_keys builder for standalone Home Manager hosts. Not a
# module by itself -- call it with the list of trusted device names (see
# lib/trusted-keys.nix for the full set) to get back a home-manager module
# fragment. Defaults to trusting every known device, which is today's
# intended behavior (full mesh); a host wanting to diverge just passes an
# explicit `trust` list instead, without touching this file or any other
# host's file.
#
# Usage in a per-host profile:
#   imports = [ (import ./authorized-keys.nix { }) ];                       # trust everyone
#   imports = [ (import ./authorized-keys.nix { trust = [ "nexus" ]; }) ];   # trust only nexus
{ trust ? builtins.attrNames (import ../lib/trusted-keys.nix) }:
{ lib, pkgs, ... }:
let
  allKeys = import ../lib/trusted-keys.nix;
  keysText = lib.concatMapStringsSep "\n" (name: allKeys.${name}) trust + "\n";
  keysFile = pkgs.writeText "authorized_keys" keysText;
in
{
  # Deliberately NOT home.file -- that symlinks into /nix/store, and sshd's
  # StrictModes check walks the *entire* resolved path chain, rejecting auth
  # with "bad ownership or modes for directory /nix/store" since the store is
  # necessarily world-writable-with-sticky-bit for Nix itself to work. NixOS's
  # own openssh module sidesteps this by keeping authorized_keys outside
  # $HOME entirely; standalone home-manager has no equivalent, so copy a
  # real, regular, correctly-permissioned file into place instead.
  home.activation.authorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.ssh"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 700 "$HOME/.ssh"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -f ${keysFile} "$HOME/.ssh/authorized_keys"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$HOME/.ssh/authorized_keys"
  '';
}
