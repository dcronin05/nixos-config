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
      export PATH="${pkgs.coreutils}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.curl}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:$PATH"
      $DRY_RUN_CMD mkdir -p "$HOME/.local/bin"
      $DRY_RUN_CMD curl -fsSL https://getmoshi.app/install.sh | $DRY_RUN_CMD sh
    fi
  '';

  sops.secrets.moshi_device_token = { };

  # Downloading the binary is not enough to get notifications. Two further steps
  # are required and both are imperative:
  #
  #   pair     registers this machine as a Moshi host, deriving a per-host ID and
  #            secret from the account-level token in the iPhone app
  #            (Settings -> Integrations)
  #   install  writes the hook entries into each agent CLI's config
  #
  # Without them a new device comes up with a running daemon, no hooks, and no
  # errors -- it is simply silent, which is a miserable thing to debug. This
  # closes that gap so a fresh machine is paired by `home-manager switch` alone.
  #
  # `--store file` is deliberate: the secret store defaults to Keychain on macOS,
  # which is unavailable in headless sessions. The file store works everywhere and
  # keeps behaviour identical across the fleet.
  #
  # Guarded on secrets.json so an already-paired machine is never re-paired, and
  # so `install` cannot silently rewrite hook paths on a working host.
  home.activation.moshiPair = lib.hm.dag.entryAfter [ "moshiHook" "sops-nix" ] ''
    MOSHI_HOOK="$HOME/.local/bin/moshi-hook"
    TOKEN_FILE="${config.sops.secrets.moshi_device_token.path}"
    if [ -x "$MOSHI_HOOK" ] && [ -r "$TOKEN_FILE" ] && [ ! -f "$HOME/.config/moshi/secrets.json" ]; then
      $DRY_RUN_CMD "$MOSHI_HOOK" pair --store file --token "$(cat "$TOKEN_FILE")"
      $DRY_RUN_CMD "$MOSHI_HOOK" install
    fi
  '';
}
