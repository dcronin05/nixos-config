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
{ lib, ... }:
let
  allKeys = import ../lib/trusted-keys.nix;
in
{
  home.file.".ssh/authorized_keys".text =
    lib.concatMapStringsSep "\n" (name: allKeys.${name}) trust + "\n";
}
