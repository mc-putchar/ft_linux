#!/usr/bin/env bash
# master_deploy.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "========================================================"
echo " Starting Headless Infrastructure Deployment Blueprint "
echo "========================================================"

echo "[*] Cleaning up existing legacy VM frameworks..."
virsh --connect="$LIBVIRT_DEFAULT_URI" destroy "$VM_NAME" 2>/dev/null || true
virsh --connect="$LIBVIRT_DEFAULT_URI" undefine "$VM_NAME" 2>/dev/null || true

echo "[*] Provisioning raw virtual machine container..."
./provision.sh

echo "[*] Power-cycling the domain to apply serial device mapping..."
# This forces libvirt to read the updated XML config cleanly on the next cold boot
virsh --connect="$LIBVIRT_DEFAULT_URI" start "$VM_NAME"
sleep 2
virsh --connect="$LIBVIRT_DEFAULT_URI" destroy "$VM_NAME" 2>/dev/null || true

echo "[*] Booting into headless serial mode..."
virsh --connect="$LIBVIRT_DEFAULT_URI" start "$VM_NAME"

echo "[*] Sending 'Enter' keycode to bypass Arch Bootloader Menu..."
sleep 4
virsh --connect="$LIBVIRT_DEFAULT_URI" send-key "$VM_NAME" KEY_ENTER

echo "[*] Waiting for live image system initialization (approx 25s)..."
sleep 25

echo "[*] Unlocking root access and launching SSH daemon over serial..."
# We send the configuration commands directly down the virtual serial interface
(
  echo ""
  sleep 1
  echo "echo 'root:root' | chpasswd"
  sleep 1
  echo "systemctl start sshd"
  sleep 1
) | virsh --connect="$LIBVIRT_DEFAULT_URI" console "$VM_NAME" > /dev/null || true

echo "========================================================"
echo "[*] Validating secure host communication terminal..."
./manage.sh ssh "echo 'Handshake verified! Headless terminal environment is ready.'"
echo "========================================================"
