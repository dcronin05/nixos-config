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
}
