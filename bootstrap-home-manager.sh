#!/usr/bin/env bash
# ==============================================================================
# STANDALONE HOME MANAGER BOOTSTRAP (macOS / non-NixOS Linux)
# ==============================================================================
# For Tier 2 "Standalone Home Manager" targets (see docs/architecture.md) --
# any machine that is NOT a full NixOS install: macOS, WSL, CachyOS, Debian,
# etc. Installs Nix if missing, then runs `home-manager switch` against this
# machine's flake output (dcronin05@<hostname>).
#
# NOTE: This script is a true 1-click installer. It uses Home Manager activation 
# hooks to silently fetch and install proprietary binaries (like `moshi-hook`) 
# in the background without manual intervention.
#
# NOT for bare-metal NixOS installs -- use install.sh for that instead. This
# script never partitions or formats anything; it only touches Nix's own
# store/profile and your dotfiles (with automatic backups on conflict).
# ==============================================================================
set -e

# `hostname -s` strips the ".local"/domain suffix macOS's mDNS hostname often
# has, so this matches the bare hostnames used as flake output names
# (dcronin05@macbook, dcronin05@forge, etc.) on both platforms.
#
# NOTE: this script alone does not enroll a new device in the SSH trust mesh
# (see lib/trusted-keys.nix) -- that needs the device's own key added to that
# file, plus every *other* device re-pulling and re-switching to pick it up.
HOSTNAME=$(hostname -s 2>/dev/null || hostname)
FLAKE_TARGET="dcronin05@${HOSTNAME}"

echo "==> Bootstrapping standalone Home Manager for ${FLAKE_TARGET}"

# 1. Install Nix if missing (Determinate installer -- same command on both
#    macOS and Linux, enables flakes by default, systemd-integrated on Linux).
if ! command -v nix >/dev/null 2>&1; then
  echo "==> Nix not found, installing via the Determinate Systems installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  echo ""
  echo "==> Nix installed. Open a NEW shell (so the Nix profile is on PATH),"
  echo "    then re-run this script to finish the Home Manager switch."
  exit 0
else
  echo "==> Nix already installed: $(nix --version)"
fi

# 2. Run home-manager switch, auto-backing-up any conflicting dotfiles
#    (~/.ssh/config, ~/.config/nvim, etc.) instead of failing on first run.
echo "==> Running home-manager switch for ${FLAKE_TARGET}..."
nix run home-manager/master -- switch --flake ".#${FLAKE_TARGET}" -b backup

echo ""
echo "==================================================="
echo "SUCCESS. Home Manager is now managing this machine."
echo "==================================================="

# 3. Linux-only: point out the login-shell step, but don't try to automate it.
#    Changing /etc/shells and the login shell needs root, which this script
#    can't silently assume -- macOS already defaults to zsh since Catalina,
#    so this step is Linux-specific.
if [[ "$(uname -s)" == "Linux" ]]; then
  ZSH_PATH="$HOME/.nix-profile/bin/zsh"
  if [[ -x "$ZSH_PATH" ]] && [[ "$SHELL" != "$ZSH_PATH" ]]; then
    echo ""
    echo "NOTE: zsh is installed at $ZSH_PATH but isn't your login shell yet."
    echo "This machine's OS (not Nix) owns login-shell state, so it can't be"
    echo "changed automatically. One-time manual step (needs your sudo password):"
    echo ""
    echo "  echo \"$ZSH_PATH\" | sudo tee -a /etc/shells"
    echo "  chsh -s \"$ZSH_PATH\""
    echo ""
  fi
fi


