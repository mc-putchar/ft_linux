# ft_linux

LFS - Linux from Scratch

## Requirements

- qemu, virt-install, virsh
- USB drive (at least 64GB)

## Steps

[*] `./provision.sh`
[*] `./manage.sh console`
[*] Run partition_disk.sh and bootstrap_host.sh
[*] `./manage.sh restart`
[*] `./manage.sh ssh`
[*] Build LFS partitions under `/dev/vda3/@lfs`
[*] `./manage.sh run-script` to execute a script on the VM
