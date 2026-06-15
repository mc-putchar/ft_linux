#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

usage() {
    echo "Usage: $0 {start|stop|status|console|ssh|transfer}"
    echo "  status   : Check if the VM is running"
    echo "  start    : Spin up the VM"
    echo "  stop     : Gracefully shut down the VM"
    echo "  restart  : Restart the VM (destroy then start)"
    echo "  console  : Connect to the text console (for setup)"
    echo "  ssh      : Connect to the guest OS via SSH"
    echo "  transfer : Interactive SFTP session for file management"
    echo "  snapshot-create : Take a safe snapshot before toolchain installation"
    echo "  snapshot-revert : Revert to the last safe snapshot if needed"
    echo "  generate-checksum : Calculate and save the disk image checksum"
    echo "  run-script [file] : Transfer a host script and run it as root on the guest"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1

case "$COMMAND" in
    status)
        virsh list --all | grep "$VM_NAME" || echo "$VM_NAME is not tracked or defined."
        ;;
    start)
        echo "Starting $VM_NAME..."
        virsh start "$VM_NAME"
        ;;
    stop)
        echo "Shutting down $VM_NAME gracefully..."
        virsh shutdown "$VM_NAME"
        ;;
    restart)
        echo "Restarting $VM_NAME..."
        virsh destroy "$VM_NAME" 2>/dev/null || true
        virsh start "$VM_NAME"
        ;;
    console)
        echo "Connecting to serial console. Use 'Ctrl + ]' to exit."
        virsh console "$VM_NAME"
        ;;
    ssh)
        echo "Connecting via SSH to localhost:$HOST_SSH_PORT..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$HOST_SSH_PORT" root@127.0.0.1
        ;;
    transfer)
        echo "Opening SFTP session..."
        sftp -P "$HOST_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@127.0.0.1
        ;;
    snapshot-create)
        echo "Taking a safe snapshot of ScamOS..."
        virsh snapshot-create-as "$VM_NAME" --name "before-toolchain" --description "Pre-compilation backup"
        ;;
    snapshot-revert)
        echo "Reverting ScamOS to last safe state..."
        virsh snapshot-revert "$VM_NAME" "before-toolchain"
        ;;
    generate-checksum)
        echo "Calculating disk image checksum..."
        virsh shutdown "$VM_NAME" 2>/dev/null || true
        shasum -a 256 "$DISK_PATH" > "$SCRIPT_DIR/checksum.sha256"
        echo "Saved checksum to checksum.sha256"
        ;;
    *)
        usage
        ;;
    run-script)
            if [ ${#2} -eq 0 ] || [ ! -f "$2" ]; then
                echo "ERROR: Please specify a valid local script file to execute." >&2
                echo "Usage: $0 run-script path/to/script.sh" >&2
                exit 1
            fi

            SCRIPT_FILE="$2"
            SCRIPT_NAME=$(basename "$SCRIPT_FILE")
            REMOTE_TMP="/tmp/$SCRIPT_NAME"

            echo "[*] Transferring '$SCRIPT_FILE' to guest VM..."
            scp -P "$HOST_SSH_PORT" \
                -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                "$SCRIPT_FILE" root@127.0.0.1:"$REMOTE_TMP"

            echo "[*] Executing '$SCRIPT_NAME' inside guest VM..."
            ssh -p "$HOST_SSH_PORT" \
                -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                root@127.0.0.1 "chmod +x '$REMOTE_TMP' && '$REMOTE_TMP'; RET=\$?; rm -f '$REMOTE_TMP'; exit \$RET"
            ;;
esac
