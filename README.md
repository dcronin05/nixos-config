# NixOS Flake Infrastructure

This repository contains a fully declarative, hardware-agnostic, and SOPS-encrypted NixOS infrastructure.

Because secrets are encrypted with `sops-nix` and the hardware configuration uses disk labels instead of hardcoded UUIDs, this repository is 100% public and can be instantly deployed to any piece of hardware for a true bare-metal restore.

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

> [!WARNING]
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
