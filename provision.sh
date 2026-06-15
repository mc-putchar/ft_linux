#!/usr/bin/env bash
# Script to provision a new VM for the ft_linux project using virt-install and libvirt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "Checking environment..."
if [ ! -d "$USB_MOUNT_DIR" ]; then
    echo "ERROR: USB mount directory '$USB_MOUNT_DIR' not found. Please plug in your drive." >&2
    exit 1
fi

mkdir -p "$(dirname "$DISK_PATH")"

if [ ! -f "$ISO_PATH" ]; then
    echo "ISO not found at '$ISO_PATH'. Downloading from $DOWNLOAD_SOURCE..."
    wget -O "$ISO_PATH" "$DOWNLOAD_SOURCE"
    echo "Verifying ISO integrity..."
    echo "$SHA256_CHECKSUM  $ISO_PATH" | sha256sum -c -
fi

echo "Provisioning VM: $VM_NAME"
echo "Storage Location: $DISK_PATH ($DISK_SIZE_GB GB)"

virt-install \
    --connect="$LIBVIRT_DEFAULT_URI" \
    --name="$VM_NAME" \
    --memory="$RAM_MB" \
    --vcpus="$VCPUS" \
    --disk path="$DISK_PATH",size="$DISK_SIZE_GB",format=qcow2,bus=virtio \
    --cdrom "$ISO_PATH" \
    --network none \
    --qemu-commandline="-netdev user,id=net0,hostfwd=tcp::${HOST_SSH_PORT}-:22 -device virtio-net-pci,netdev=net0" \
    --os-variant="$OS_VARIANT" \
    --graphics none \
    --console pty,target_type=serial \
    --noautoconsole

echo "[*] Injection mapping modifications via virt-xml..."
virt-xml --connect="$LIBVIRT_DEFAULT_URI" "$VM_NAME" \
    --edit --console target_type=serial

echo "--------------------------------------------------------"
echo "VM '$VM_NAME' has been successfully defined."
echo "To view the installation console, run: virsh console $VM_NAME"
echo "--------------------------------------------------------"
