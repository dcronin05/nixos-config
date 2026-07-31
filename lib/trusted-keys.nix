# Canonical, single source of truth for every Nix-managed device's SSH
# public key. Pure data -- no policy here. Each host's own profile decides
# which subset of these it actually trusts (see home/authorized-keys.nix for
# the Tier 2 helper, modules/common.nix for Tier 1/nexus).
#
# Deliberately scoped to Nix-managed devices only for now (debian-vm is a
# separate, non-Nix machine and isn't part of this mesh yet). One key per
# device, used for everything that device does -- not scoped per-destination.
{
  nexus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLK21gBMX/VEf6xq7kGywRgcxPjxVe2gsDz16WoxlTQ dcronin05@nexus";

  forge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaQa/zzzv2HJypdaNUm/ov0JVAdMCZlCwHCGiawyQth dcronin05@forge";

  # Reused verbatim from modules/common.nix's pre-existing authorizedKeys list.
  # laptop CONFIRMED 2026-07-31 (forge -> laptop went from password-prompt to
  # instant key auth after laptop pulled+switched) -- it really is laptop's
  # general-purpose identity, not scoped to nexus only. macbook/M4-Mini keys
  # were reused on the same assumption but not yet independently tested.
  laptop  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIy0Cu8+WCMQt3Qv84SrhaB6WMLKePPiz+8zDMBYWnA0 dcronin05@laptop";
  macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFXJ/DATZ3wSFzpPFyaYisSS+IyzK3eE0GERWnSmxg3h dcronin05@Daniels-MacBook-Pro.local";
  m4mini  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEe6oeFzP00bx7VSsAf+qxXff8NKhb9DrqqPly0vxdN m4-mini";

  # gpantz intentionally omitted -- access was never actually confirmed
  # working from any device, add it once that's sorted.
}
