# NixOS Flake Infrastructure

This repository contains a fully declarative, hardware-agnostic, and SOPS-encrypted NixOS infrastructure.

Because secrets are encrypted with `sops-nix` and the hardware configuration uses disk labels instead of hardcoded UUIDs, this repository is 100% public and can be instantly deployed to any piece of hardware for a true bare-metal restore.

## Bare-Metal Disaster Recovery Guide

Follow these commands in the console of your new NixOS VM or physical machine after booting the **NixOS Minimal ISO**.

### 1. Elevate Privileges
```bash
sudo su
```

### 2. Partition the Drive (Generation 2 UEFI / EFI)
*Note: Adjust `/dev/sda` to your actual block device if necessary (e.g., `/dev/nvme0n1`).*
```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 boot on
parted /dev/sda -- mkpart primary 512MiB 100%
```

### 3. Format the Partitions (Hardware Agnostic)
> [!IMPORTANT]
> You **must** use the exact labels `boot` and `nixos`. The `hardware-configuration.nix` in this repository relies on these labels to mount the drives automatically, making the configuration completely hardware-agnostic.

```bash
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2
```

### 4. Mount the Partitions
```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

### 5. Inject your SOPS Master Key
Because SOPS needs to decrypt `secrets.yaml` during the installation (which contains your Tailscale state and SSH identity), you must inject your backed-up `keys.txt` age key *before* running the install.

```bash
# Create the directory structure for your user
mkdir -p /mnt/home/dcronin05/.config/sops/age/

# Open nano and paste your keys.txt contents from your secure backup
nano /mnt/home/dcronin05/.config/sops/age/keys.txt

# Ensure permissions are perfectly restricted
chmod 600 /mnt/home/dcronin05/.config/sops/age/keys.txt
```

### 6. Clone and Install
Because the NixOS Minimal ISO does not ship with `git`, we will temporarily pull it in using `nix-shell`.

```bash
# Drop into a shell with git installed
nix-shell -p git

# Clone this repository
cd /mnt/etc/nixos
git clone https://github.com/dcronin05/nixos-config.git
cd nixos-config

# Run the final installation
nixos-install --flake .#nexus
```

### 7. Reboot
```bash
reboot
```
