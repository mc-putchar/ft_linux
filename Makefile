NAME := ft_linux
AUTHORS := mcutura

SHELL := /bin/bash
SESSION := --connect qemu:///session

VM_NAME := LFS-host
RAM_MB := 8192
VCPUS := 12

SSH_KEY ?= ${HOME}/.ssh/id_rsa.pub
HOST_SSH_PORT := 2242
PORT_FORWARDING := hostfwd=tcp::$(HOST_SSH_PORT)-:22

DISK_SIZE_GB := 21
MOUNT_DIR := /media/${USER}/SCAMDISK
ARCHBOX_PATH := $(MOUNT_DIR)/archbox.qcow2
DISK_PATH := $(MOUNT_DIR)/lfs-target.qcow2
VM_XML := $(MOUNT_DIR)/$(VM_NAME).xml
USER_DATA := host/user-data

OS_VARIANT := archlinux
VM_IMGDIR := ${HOME}/goinfre/VMs
ARCH_BOX_URL := https://fastly.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg-20260615.545059.qcow2
ARCH_BOX_IMG := $(VM_IMGDIR)/Arch-Linux-x86_64-cloudimg-20260615.545059.qcow2

# Colors
RED := \033[31m
GRN := \033[32m
MAG := \033[35m
MAB := \033[1;35m
CYA := \033[36m
CYB := \033[1;36m
NC  := \033[0m

.PHONY: help start stop console ssh clean install dump part-lfs

help:	# Show this helpful message
	@awk 'BEGIN { FS = ":.*#"; \
	printf "$(GRN)$(NAME)$(NC)\nby: $(AUTHORS)\t@$(GRN)42 Berlin$(NC)\n\n"; \
	printf "Usage:\n\t$(CYB)make $(MAG)<target>$(NC)\n" } \
	/^[A-Za-z_0-9-]+:.*?#/ { printf "$(MAB)%-16s $(CYA)%s$(NC)\n", $$1, $$2}' \
	Makefile

start:	# Start Host VM
	virsh $(SESSION) start $(VM_NAME)

stop:	# Stop Host VM
	virsh $(SESSION) destroy $(VM_NAME)

console:	# Connect to Host VM console
	virsh $(SESSION) console $(VM_NAME)

ssh:
	ssh -p $(HOST_SSH_PORT) lfs@localhost

clean:	# Remove Host VM and its storage
	$(info Cleaning up...)
	-rm -f $(USER_DATA)
	-virsh $(SESSION) destroy $(VM_NAME)
	-find ~/ -name "*$(VM_NAME)_VARS.fd*" -delete 2>/dev/null
	-virsh $(SESSION) undefine $(VM_NAME) --snapshots-metadata --remove-all-storage
	-ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "[localhost]:$(HOST_SSH_PORT)"

$(VM_IMGDIR):
	@mkdir -p $@

$(ARCH_BOX_IMG): | $(VM_IMGDIR)
	@echo "$(CYA)Downloading Arch Base Image...$(NC)"
	@wget -O $@ $(ARCH_BOX_URL)

$(ARCHBOX_PATH): $(ARCH_BOX_IMG) | $(MOUNT_DIR)
	@echo -e "$(CYA)Preparing Arch-box host engine...$(NC)"
	cp $(ARCH_BOX_IMG) $(ARCHBOX_PATH)
	qemu-img resize $(ARCHBOX_PATH) $(DISK_SIZE_GB)G

$(DISK_PATH): | $(MOUNT_DIR)
	@echo -e "$(CYA)Creating empty LFS target disk...$(NC)"
	qemu-img create -f qcow2 $(DISK_PATH) $(DISK_SIZE_GB)G

$(USER_DATA):
	sed "s|<SSH_KEY>|$$(cat $(SSH_KEY))|g" host/user-data.yaml > $@
	sed -i "s|<PASSWD_HASH>|$$(openssl passwd -6)|g" $@

install: $(USER_DATA) $(ARCHBOX_PATH) $(DISK_PATH)	# Install VM from basic Arch-box
	virt-install $(SESSION) --name $(VM_NAME) \
		--memory $(RAM_MB) \
		--vcpus $(VCPUS) \
		--disk path=$(ARCHBOX_PATH),format=qcow2,bus=virtio \
		--disk path=$(DISK_PATH),format=qcow2,bus=virtio \
		--check disk_size=off \
		--os-variant $(OS_VARIANT) \
		--network user \
		--qemu-commandline="-netdev user,id=net0,$(PORT_FORWARDING) -device virtio-net-pci,netdev=net0" \
		--import \
		--cloud-init user-data=$(USER_DATA) \
		--graphics none \
		--console pty,target_type=serial \
		--noautoconsole
	rm -f $(USER_DATA)

dump:	# Dump XML profile
	virsh $(SESSION) dumpxml $(VM_NAME) > $(VM_XML)

part-lfs:	# Run LFS partitioning
	@echo -e "$(CYA)Injecting partitioning script via SSH...$(NC)"
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		lfs@localhost -i $(SSH_KEY) -p $(HOST_SSH_PORT) 'bash -s' < scripts/partition_disk.sh

# Backup plans
.PHONY: snapshot revert snapshot-list

snapshot:	# Create a checkpoint (Usage: make snapshot TAG=pre-nuked)
	@if [ -z "$(TAG)" ]; then echo -e "$(RED)Error: Choose a name. Example: make snapshot TAG=pre-nuked$(NC)"; exit 1; fi
	virsh $(SESSION) snapshot-create-as $(VM_NAME) $(TAG) "Checkpoint at $(TAG)" --atomic

revert:		# Revert to a checkpoint (Usage: make revert TAG=pre-nuked)
	@if [ -z "$(TAG)" ]; then echo -e "$(RED)Error: Specify a name. Example: make revert TAG=pre-nuked$(NC)"; exit 1; fi
	virsh $(SESSION) snapshot-revert $(VM_NAME) $(TAG)

snapshot-list:	# List all existing VM checkpoints
	virsh $(SESSION) snapshot-list $(VM_NAME)
