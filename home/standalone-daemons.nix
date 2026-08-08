# ==============================================================================
# STANDALONE DAEMONS MODULE
# ==============================================================================
# This module is imported by standalone Home Manager profiles (macOS, WSL, CachyOS).
# It defines user-level background daemons (like `etserver`) that are otherwise 
# handled system-wide by NixOS in `modules/common.nix`.
# 
# Why don't we put this in `cli.nix` universally?
# Because NixOS already binds `etserver` to TCP port 2022 as `root`. If we ran 
# a universal user-level daemon, it would crash on NixOS due to port conflicts.
# This file provides a DRY solution for non-NixOS environments to get daemons.
# ==============================================================================

{ config, pkgs, lib, ... }:

{
  # Linux (WSL / CachyOS / Debian)
  # Run etserver as a native systemd user service.
  systemd.user.services.etserver = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Eternal Terminal Daemon";
      After = [ "network.target" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.eternal-terminal}/bin/etserver --cfgfile=/dev/null";
      Restart = "always";
    };
  };

  # macOS
  # Run etserver as a native launchd user agent.
  launchd.agents.etserver = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.eternal-terminal}/bin/etserver" "--cfgfile=/dev/null" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/etserver.err.log";
      StandardOutPath = "/tmp/etserver.out.log";
    };
  };

  # NOTE: the moshi-hook daemon used to live here. It moved to `home/moshi.nix`
  # so that module owns the whole lifecycle (fetch, pair, install hooks, run) and
  # so it reaches EVERY host. This file is imported only by standalone Home
  # Manager profiles, which excluded `nexus` -- meaning nexus downloaded and
  # paired moshi-hook but never ran it. moshi-hook is safe to run universally
  # because it binds a per-user unix socket, not a privileged port, so the
  # etserver conflict that motivates this module does not apply to it.
}
