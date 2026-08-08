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

  # Named to match what the Moshi app calls it. Note it is ACCOUNT-level and
  # shared by every host -- there is one key here, not one per device. Each
  # machine derives its own host ID and host secret at pair time, and those stay
  # local (~/.config/moshi/secrets.json), never in the vault.
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
    if [ -x "$MOSHI_HOOK" ]; then
      # Pair only once -- deriving a fresh host identity on every activation would
      # churn hosts in the app.
      if [ -r "$TOKEN_FILE" ] && [ ! -f "$HOME/.config/moshi/secrets.json" ]; then
        $DRY_RUN_CMD "$MOSHI_HOOK" pair --store file --token "$(cat "$TOKEN_FILE")"
      fi
      # Install hooks on EVERY activation. It is idempotent (reports "current"
      # for anything already wired) and self-healing: it picks up agent CLIs
      # installed after pairing, and repairs stale binary paths. This machine had
      # hooks pointing at a Homebrew copy of moshi-hook while the daemon ran the
      # one under ~/.local/bin -- exactly the drift this prevents.
      $DRY_RUN_CMD "$MOSHI_HOOK" install || true
    fi
  '';

  # The daemon lives here rather than in `standalone-daemons.nix` so this module
  # owns the whole lifecycle and reaches every host. standalone-daemons.nix is
  # imported only by the standalone profiles, which excluded `nexus` -- so nexus
  # paired but never ran. moshi-hook binds a per-user unix socket rather than a
  # privileged port, so the etserver conflict motivating that module is not an
  # issue here.
  #
  # On NixOS this is a systemd USER service, so it needs `users.users.<n>.linger`
  # to run without an active login session (already set for nexus).
  systemd.user.services.moshi-hook = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Moshi Hook Daemon";
      After = [ "network.target" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${config.home.homeDirectory}/.local/bin/moshi-hook serve";
      Restart = "always";
    };
  };

  launchd.agents.moshi-hook = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${config.home.homeDirectory}/.local/bin/moshi-hook" "serve" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/moshi-hook.err.log";
      StandardOutPath = "/tmp/moshi-hook.out.log";
    };
  };
}
