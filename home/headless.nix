# ==============================================================================
# HEADLESS LINUX HOME MANAGER PROFILE (WSL / DEBIAN / ETC)
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
#
# This profile is specifically designed for non-NixOS headless environments.
# (For example, Ubuntu running under WSL or a standalone Debian server where you 
# are only using Nix package manager).
#
# It imports `base.nix` to get the exact same CLI environment as everything else.
# It explicitly avoids graphical dependencies like WezTerm.
# ==============================================================================

{ config, pkgs, lib, ... }:

{
  imports = [
    ./base.nix
    (import ./authorized-keys.nix { })
  ];

  # win32yank: bridges Neovim's system clipboard ("+y/"+p) to the Windows
  # clipboard under WSL. Not a real nixpkgs candidate -- it's a prebuilt
  # Windows .exe, not something Nix cross-builds here -- so it's fetched
  # imperatively during activation instead, same escape hatch as the (now
  # unused) ghAuth activation hook in cli.nix. Mirrors what the old,
  # deprecated nvim-config/bootstrap.sh used to do by hand on every fresh
  # WSL machine; this makes that step reproducible instead of tribal
  # knowledge. No-ops instantly on non-WSL Linux (checked via /proc/version)
  # and if the binary is already present.
  home.activation.win32yank = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if grep -qi microsoft /proc/version 2>/dev/null; then
      WIN32YANK="$HOME/.local/bin/win32yank.exe"
      if [ ! -x "$WIN32YANK" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/bin"
        $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL -o /tmp/win32yank.zip \
          https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
        $DRY_RUN_CMD ${pkgs.unzip}/bin/unzip -o /tmp/win32yank.zip -d "$HOME/.local/bin" win32yank.exe
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod +x "$WIN32YANK"
      fi
    fi
  '';
}
