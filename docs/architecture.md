# 3-Tier Modular Architecture

This repository is designed around a strict 3-tier structure that allows full NixOS machines, headless Linux servers, and Apple Silicon Macs to share the exact same CLI configuration without duplicating code or polluting headless environments with graphical dependencies.

## The Foundation (`home/base.nix`)
Every single device profile in this repository must import `home/base.nix`.
This file serves two purposes:
1. It abstracts away the boilerplate of `home.username`, `home.stateVersion`, and dynamically resolves `home.homeDirectory` depending on whether the target is macOS or Linux.
2. It imports `home/cli.nix` and `home/neovim.nix`.

## The Universal CLI (`home/cli.nix`)
This is the heart of the user experience. By defining all user-facing terminal packages (`htop`, `wget`, `lsd`, `sops`) inside `cli.nix` (which is managed by Home Manager), we ensure that macOS machines receive the exact same packages as NixOS machines.
- **Do not move CLI tools to `modules/common.nix`**. If you do, macOS will not receive them.
- **Terminal Agnosticism**: Starship and Zellij are configured using hardcoded 24-bit TrueColor hex codes to ensure they look identical regardless of the host terminal emulator's theme.

## The Device Profiles
The repository provides 4 templates for devices:

### 1. NixOS Headless Servers (`home/nexus.nix`)
Designed for servers like `nexus`. 
- Imports `base.nix`.
- Does **not** import WezTerm to avoid compiling X11/Wayland dependencies on a server.
- Relies on `modules/common.nix` for OS-level daemon configuration (SSH, Tailscale).

### 2. Standalone Home Manager - macOS (`home/macos.nix`)
Designed for Apple Silicon devices like `macbook` and `M4-Mini`.
- Imports `base.nix`.
- Imports `wezterm.nix` to configure the local graphical terminal emulator.

### 3. Standalone Home Manager - Linux (`home/laptop.nix` / `home/headless.nix`)
Designed for non-NixOS Linux distributions (like CachyOS, Ubuntu WSL, Debian).
- Imports `base.nix`.
- May or may not import `wezterm.nix` depending on if the host is graphical or headless.

### 4. Graphical NixOS Machines (`home/gui.nix`)
A future placeholder for full NixOS desktop environments.
- Imports `base.nix` and `wezterm.nix`.
- Relies on `modules/gui.nix` for OS-level display server (Wayland) and desktop environment configs.

## Flake Entrypoint (`flake.nix`)
The `flake.nix` file strictly separates `nixosConfigurations` (which build the whole OS and evaluate `modules/common.nix`) from `homeConfigurations` (which only build the user profile using `mkHome`).
