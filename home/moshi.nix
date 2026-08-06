# ==============================================================================
# MOSHI TERMINAL INTEGRATION
# ==============================================================================
# This module is imported universally by `base.nix`.
# It automates the installation of `moshi-hook`, a proprietary daemon that 
# bridges the CLI environment to the Moshi iOS app for Live Activities and 
# Remote Approvals.
#
# Because `moshi-hook` is not in nixpkgs, we use an activation hook to fetch it.
# We explicitly inject `gnutar`, `gzip`, and `coreutils` into the hook's PATH 
# so the install script has the dependencies it needs to extract the binary.
# ==============================================================================

{ config, pkgs, lib, ... }:

{
  home.activation.moshiHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MOSHI_HOOK="$HOME/.local/bin/moshi-hook"
    if [ ! -x "$MOSHI_HOOK" ]; then
      export PATH="${pkgs.coreutils}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.curl}/bin:$PATH"
      $DRY_RUN_CMD mkdir -p "$HOME/.local/bin"
      $DRY_RUN_CMD curl -fsSL https://getmoshi.app/install.sh | $DRY_RUN_CMD sh
    fi
  '';
}
