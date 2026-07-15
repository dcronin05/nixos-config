#!/usr/bin/env bash
# ==============================================================================
# BARE-METAL DISASTER RECOVERY INSTALLER
# ==============================================================================
# Purpose: This script automates the dangerous and error-prone process of manually 
#          partitioning and formatting blank drives during a disaster recovery.
#
# Hardware-Agnostic Design:
#          Instead of hardcoding drive paths (like /dev/sda1) in the NixOS config, 
#          this script specifically formats the partitions with the exact labels 
#          'nixos' and 'boot'. The NixOS hardware-configuration.nix then mounts 
#          by label, meaning this exact configuration can be effortlessly deployed 
#          onto a tiny Raspberry Pi SD card, a massive NVMe drive, or a Hyper-V VM 
#          without changing a single line of code.
# ==============================================================================
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <block-device>"
  echo "Example: $0 /dev/sda"
  echo ""
  echo "Available block devices:"
  lsblk -d -n -o NAME,SIZE,MODEL | grep -v loop
  exit 1
fi

DEVICE=$1

echo "=========================================="
echo "WARNING: This will DESTROY ALL DATA on $DEVICE."
echo "=========================================="
read -p "Are you sure? (y/N): " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
  echo "Aborting."
  exit 1
fi

echo "==> Unmounting any existing partitions to prevent device busy errors..."
umount -R /mnt 2>/dev/null || true

echo "==> Partitioning $DEVICE..."
parted -s "$DEVICE" -- mklabel gpt
parted -s "$DEVICE" -- mkpart ESP fat32 1MiB 512MiB
parted -s "$DEVICE" -- set 1 boot on
parted -s "$DEVICE" -- mkpart primary 512MiB 100%

# Allow kernel to recognize new partitions
sleep 2

# Handle NVMe vs SATA partition naming (e.g., nvme0n1p1 vs sda1)
if [[ "$DEVICE" == *nvme* ]] || [[ "$DEVICE" == *loop* ]] || [[ "$DEVICE" == *mmcblk* ]] || [[ "$DEVICE" == *vd* ]]; then
  PART_BOOT="${DEVICE}p1"
  PART_ROOT="${DEVICE}p2"
else
  PART_BOOT="${DEVICE}1"
  PART_ROOT="${DEVICE}2"
fi

# Fallback specifically for Hyper-V if it passes /dev/sda but names it /dev/sda1
if [ ! -b "$PART_BOOT" ]; then
  PART_BOOT="${DEVICE}1"
  PART_ROOT="${DEVICE}2"
fi

echo "==> Formatting partitions with hardware-agnostic labels..."
mkfs.fat -F 32 -n boot "$PART_BOOT"
# Use -F to forcefully overwrite existing ext4 filesystems without prompting
mkfs.ext4 -F -L nixos "$PART_ROOT"

echo "==> Mounting partitions..."
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

echo "==> Preparing SOPS directory..."
mkdir -p /mnt/home/dcronin05/.config/sops/age/

echo "====================================================="
echo "SUCCESS: Hardware prepared and mounted at /mnt."
echo "====================================================="
echo ""
echo "NEXT STEPS:"
echo "1. Inject your SOPS master key (keys.txt):"
echo "   nano /mnt/home/dcronin05/.config/sops/age/keys.txt"
echo "   chmod 600 /mnt/home/dcronin05/.config/sops/age/keys.txt"
echo ""
echo "2. Run the NixOS Installer:"
echo "   nixos-install --flake .#nexus"
echo "====================================================="
