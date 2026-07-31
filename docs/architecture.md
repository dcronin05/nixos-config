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

## Cross-Device SSH Trust Mesh (`lib/trusted-keys.nix`)
Every Nix-managed device trusts every other Nix-managed device by default, without hand-adding keys pairwise. One canonical file, `lib/trusted-keys.nix`, holds pure data — one SSH public key per device, no policy. Each host's profile decides which subset of that list it actually trusts:
- **Tier 1 (`nexus`)**: `modules/common.nix` maps the list into `users.users.dcronin05.openssh.authorizedKeys.keys` directly (a plain NixOS option) — plus one hand-added, non-mesh entry for `debian-vm`, which isn't a Nix-managed device.
- **Tier 2 (standalone Home Manager)**: `home/authorized-keys.nix` is a reusable function — `(import ./authorized-keys.nix { })` trusts every device in `lib/trusted-keys.nix` by default; passing an explicit `trust = [ "nexus" ]` list lets one host diverge without touching the shared file or any other host. Every Tier 2 host profile (`headless.nix`, `laptop.nix`, `macos.nix`) imports this.

**Important implementation detail:** the Tier 2 helper deliberately does **not** use `home.file` for `~/.ssh/authorized_keys` — that symlinks into `/nix/store`, and `sshd`'s `StrictModes` check walks the *entire* resolved path chain, rejecting authentication with `bad ownership or modes for directory /nix/store` (the store is necessarily world-writable-with-sticky-bit for Nix itself to function). NixOS's own `openssh` module sidesteps this by keeping authorized keys outside `$HOME` entirely; standalone Home Manager has no such option, so `authorized-keys.nix` instead uses a `home.activation` hook to copy a real, regular, correctly-permissioned (`0600`) file into place.

**Each device has exactly one identity**, used for everything it does — not a key per destination. `debian-vm` and `gpantz` are intentionally excluded from `lib/trusted-keys.nix` for now: `debian-vm` isn't a Nix-managed device, and `gpantz` was never confirmed to have working SSH access from any device yet.

**Onboarding a new device to the mesh:**
1. Generate one keypair on the new device (`ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`) — this becomes its one identity.
2. Add its public key to `lib/trusted-keys.nix`.
3. Add `(import ./authorized-keys.nix { })` to that device's own Home Manager profile (or `openssh.authorizedKeys.keys` reference in `modules/common.nix` if it's Tier 1).
4. Push, then re-pull and re-switch/rebuild on **every existing device** — each one needs the updated `lib/trusted-keys.nix` to actually trust the new key. `bootstrap-home-manager.sh` alone does not do this step.
