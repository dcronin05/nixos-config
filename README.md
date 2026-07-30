# NixOS Flake Infrastructure

This repository contains a fully declarative, hardware-agnostic, and SOPS-encrypted NixOS infrastructure.

Because secrets are encrypted with `sops-nix` and the hardware configuration uses disk labels instead of hardcoded UUIDs, this repository is 100% public and can be instantly deployed to any piece of hardware for a true bare-metal restore.

## Architecture

This repository uses a strict **3-Tier Modular Architecture** to ensure 100% parity across vastly different devices without duplicating code.

The three supported tiers are:
1. **NixOS Headless Servers** (e.g. `nexus`)
2. **Standalone Home Manager** (e.g. `macbook` macOS, `laptop` CachyOS, WSL)
3. **Graphical NixOS Machines** (Future Desktop Linux setups)

All tiers share an identical Universal CLI Environment (Zsh, Starship, Zellij, Neovim, and core packages) while strictly isolating OS-level daemon configuration.

👉 **For a complete breakdown of how the profiles are structured, read the [Architecture Documentation](docs/architecture.md).**

### Monorepo Dotfiles (Neovim, WezTerm, etc.)

This repository uses a strict monorepo approach for dotfiles. Rather than pulling Neovim and WezTerm configurations from separate Git repositories via flake inputs, all configuration is managed directly in the local `dotfiles/` directory.

- `home/neovim.nix` wires up Neovim by pulling dependencies from `dotfiles/nvim/nix/packages.nix` and creating symlinks to `dotfiles/nvim`.
- `home/wezterm.nix` does the same for WezTerm, symlinking `dotfiles/wezterm` directly into `~/.config/wezterm`.
- **Why?** This eliminates the friction of managing multiple `flake.lock` files, prevents dependency resolution mismatch between repos, and allows atomic, instant updates across the entire environment without waiting on remote fetches.

### Passwordless `nixos-rebuild`

`modules/common.nix` has a `security.sudo.extraRules` entry scoping `NOPASSWD` to just `/run/current-system/sw/bin/nixos-rebuild` (the stable system-profile symlink, not a `/nix/store` path, so it survives package updates) — not blanket sudo. Intentional, for iterating on this repo without a password prompt every rebuild.

## Standalone Home Manager Bootstrap (macOS / non-NixOS Linux)

For Tier 2 targets (macOS, WSL, CachyOS, Debian, etc. — see [architecture docs](docs/architecture.md)) that are *not* full NixOS installs. Run this once on a new machine:

```bash
git clone https://github.com/dcronin05/nixos-config.git
cd nixos-config
./bootstrap-home-manager.sh
```

It installs Nix (Determinate Systems installer, same on both platforms) if missing, then runs `home-manager switch --flake .#dcronin05@$(hostname -s)` — the hostname must already have a matching entry in `flake.nix`'s `homeConfigurations`, or add one first (see `home/headless.nix` for the generic non-macOS Linux profile).

**Why this is a separate script from `install.sh`:** `install.sh` partitions and formats a blank disk for a bare-metal NixOS install — genuinely destructive and hardware-specific. This script never touches disk partitions; it only manages Nix's own store/profile and your dotfiles (with automatic backups on any conflict).

**One manual step on Linux only:** making zsh your login shell requires root (`/etc/shells`, `chsh`), which the script deliberately doesn't try to automate — it prints the exact two commands to run yourself. macOS has defaulted to zsh since Catalina, so this step never applies there.

## Bare-Metal Disaster Recovery Guide

Follow these commands in the console of your new NixOS VM or physical machine after booting the **NixOS Minimal ISO**.

### 1. Elevate Privileges

```bash
sudo su
```

### 1.5 Enable Remote SSH (Recommended for VMs)

If you are installing on a Hyper-V VM or a device without a keyboard/clipboard, you will need SSH to paste your configuration commands and inject your `keys.txt`.

```bash
# Set a temporary password for the root user
passwd

# Find your IP address
ip a

# Connect from your host machine:
# ssh root@<IP_ADDRESS>
```

### 2. Download the Automated Installer

Because the NixOS Minimal ISO does not ship with `git`, we will pull it in using `nix-shell` to clone this repository into a temporary RAM disk directory.

```bash
# Drop into a shell with git installed
nix-shell -p git

# Clone this repository
git clone https://github.com/dcronin05/nixos-config.git
cd nixos-config
```

### 3. Run the Automated Partition & Mount Script

This script will safely partition your designated drive (e.g., `/dev/sda` or `/dev/nvme0n1`), format it with the required hardware-agnostic labels (`nixos` and `boot`), and mount it to `/mnt`.

> \[!WARNING]
>
> This command will DESTROY ALL DATA on the target drive.

```bash
# Make the script executable and run it against your target drive
chmod +x install.sh
./install.sh /dev/sda
```

### 4. Inject your SOPS Master Key

Because SOPS needs to decrypt `secrets.yaml` during the installation (which contains your Tailscale state and SSH identity), you must inject your backed-up `keys.txt` age key *before* running the install.

```bash
# Open nano and paste your keys.txt contents from your secure backup
nano /mnt/home/dcronin05/.config/sops/age/keys.txt

# Ensure permissions are perfectly restricted
chmod 600 /mnt/home/dcronin05/.config/sops/age/keys.txt
```

### 5. Final Installation

Run the installer, targeting the `nexus` flake configuration.

```bash
nixos-install --flake .#nexus
```

### 6. Reboot

```bash
reboot
```

