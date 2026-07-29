# NixOS Flake Infrastructure

This repository contains a fully declarative, hardware-agnostic, and SOPS-encrypted NixOS infrastructure.

Because secrets are encrypted with `sops-nix` and the hardware configuration uses disk labels instead of hardcoded UUIDs, this repository is 100% public and can be instantly deployed to any piece of hardware for a true bare-metal restore.

## Architecture

### Layered home-manager modules

`home/` is composed in layers, so any host — full NixOS or standalone home-manager, CLI-only or with a desktop — pulls in only what applies to it:

- `home/cli.nix` — base layer, always imported. Shell, git, ssh, starship, etc.
- `home/desktop.nix` — GUI-only bits (currently just Ghostty). Only imported by hosts with a desktop.
- `home/neovim.nix` — the editor, wired to the `nvim-config` flake input (see below). Only imported by hosts that should get it.
- `home/wezterm.nix` — WezTerm terminal, wired to the `wezterm-config` flake input (see below).
- `home/<hostname>.nix` — the actual per-host entry point (`home/nexus.nix`, `home/laptop.nix`), which just `imports` whichever of the above apply, plus `home.username`/`home.homeDirectory`/`home.stateVersion`.

`flake.nix` wires each host to its `home/<hostname>.nix` — full-NixOS hosts via `home-manager.users.dcronin05 = import ./home/<hostname>.nix;` inside `nixosConfigurations`, standalone hosts via `homeConfigurations."dcronin05@<hostname>"` using `mkHome`. Adding a new host means: pick which layers it needs, write `home/<hostname>.nix` composing them, and add one line to `flake.nix`.

### Neovim (`nvim-config` input) & WezTerm (`wezterm-config` input)

Neovim and WezTerm configurations come from separate repos ([`nvim-config`](https://github.com/dcronin05/nvim-config) and [`wezterm-config`](https://github.com/dcronin05/wezterm-config)), pulled in as flake inputs (`flake = false`):

- `home/neovim.nix` does `xdg.configFile."nvim".source = nvim-config;`
- `home/wezterm.nix` does `xdg.configFile."wezterm".source = wezterm-config;`
- **These are pinned by `flake.lock`**. To pull updates from either repository:
  ```bash
  nix flake lock --update-input wezterm-config
  nix flake lock --update-input nvim-config
  home-manager switch --flake .#dcronin05@macbook
  ```
- A single lock-bump + rebuild picks up **both** config changes and new `nix/packages.nix` dependencies together, since `home.packages` reads that file from the fetched input at build time. The one thing that *wouldn't* be covered this way is a change needing actual NixOS system-level config (a systemd service, kernel module, etc.) rather than a home-manager package — not expected for an editor config, but worth knowing the boundary.
- On non-Nix machines, `nvim-config` has its own `bootstrap.sh` for the same dependency list via apt/dnf/pacman/brew instead — see that repo's README.

### Passwordless `nixos-rebuild`

`modules/common.nix` has a `security.sudo.extraRules` entry scoping `NOPASSWD` to just `/run/current-system/sw/bin/nixos-rebuild` (the stable system-profile symlink, not a `/nix/store` path, so it survives package updates) — not blanket sudo. Intentional, for iterating on this repo without a password prompt every rebuild.

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

