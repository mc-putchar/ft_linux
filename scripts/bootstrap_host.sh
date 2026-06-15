#!/usr/bin/env bash
set -euo pipefail

PART_BOOT="/dev/vda1"
PART_ROOT="/dev/vda3"
TARGET_MNT="/mnt/arch_host"
STUDENT_LOGIN="mcutura"

echo "[*] Mounting host ecosystem subvolume..."
mkdir -p "$TARGET_MNT"
mount -o noatime,compress=zstd:3,subvol=@host "$PART_ROOT" "$TARGET_MNT"

mkdir -p "$TARGET_MNT/boot"
mount "$PART_BOOT" "$TARGET_MNT/boot"

echo "[*] Bootstrapping core developer tools onto host..."
pacstrap -K "$TARGET_MNT" \
    base linux linux-firmware btrfs-progs openssh grub \
    base-devel git bison flex texinfo gawk python diffutils file patch

echo "[*] Generating filesystem table matrix..."
genfstab -U "$TARGET_MNT" >> "$TARGET_MNT/etc/fstab"

echo "[*] Configuring the persistent host image..."
arch-chroot "$TARGET_MNT" /usr/bin/bash <<EOF
set -euo pipefail

echo "Setting hostname..."
echo "${STUDENT_LOGIN}-host" > /etc/hostname [cite: 39]

echo "Configuring network service interfaces..."
systemctl enable systemd-networkd systemd-resolved sshd

# Expose configuration to let systemd-networkd request user-space DHCP
cat <<NET > /etc/systemd/network/20-wired.network
[Match]
Name=en* matrix* vi*

[Network]
DHCP=yes
NET

echo "Modifying SSH configuration for unprivileged hostfwd entry..."
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

echo "Setting system passwords..."
echo "root:root" | chpasswd

echo "Enabling serial console out-of-the-box for virsh console access..."
# Force GRUB to talk out of the serial bus line so virsh console works natively
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 console=ttyS0,115200n8"/' /etc/default/grub
sed -i 's/#GRUB_TERMINAL_OUTPUT.*/GRUB_TERMINAL_OUTPUT=serial/' /etc/default/grub
echo 'GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"' >> /etc/default/grub

echo "Deploying bootloader..."
grub-install --target=i386-pc /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "========================================================"
echo " Bootstrapping Finished! You can now reboot the machine. "
echo "========================================================"
