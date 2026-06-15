#!/usr/bin/env bash
# Configuration parameters for ft_linux

# --- VM Configuration ---
export VM_NAME="ScamOS"
export RAM_MB=4096
export VCPUS=4

# --- Storage Paths ---
export USB_MOUNT_DIR="/media/$USER/SCAMDISK"
export DISK_PATH="$USB_MOUNT_DIR/$VM_NAME.qcow2"
export DISK_SIZE_GB=50

# --- Installation Media ---
export DOWNLOAD_SOURCE="https://geo.mirror.pkgbuild.com/iso/2026.06.01/archlinux-2026.06.01-x86_64.iso"
export SHA256_CHECKSUM="ec7a9c89aed7a59a76266ccf723c5e88480e47d7088c4482436f882fa37c3989"
export ISO_PATH="$USB_MOUNT_DIR/archlinux-2026.06.01-x86_64.iso"
export OS_VARIANT="archlinux"

# --- Networking ---
export HOST_SSH_PORT=2242

# --- Connection URI ---
export LIBVIRT_DEFAULT_URI="qemu:///session"
