#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$(pwd)/setup-data"
DEFAULT_HYPERVISOR=""
ISO_NAME="AlmaLinux-9-latest.iso"
ARCH=$(uname -m)

# weird macOS specific behavior
if [ "$ARCH" == "arm64" ]; then
  ARCH="aarch64"
fi

ISO_PATH="$PWD/$ISO_NAME"
VM_NAME="AlmaLinux-WSO"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "[setup.sh] Choose your hypervisor:"
    echo "1) QEUM"
    echo "2) VirtualBox"
    echo "3) UTM (macOS only)"
    read -rp "[setup.sh] selection [1-3]: " hv_sel
    case "$hv_sel" in
        1) DEFAULT_HYPERVISOR="QEMU" ;;
        2) DEFAULT_HYPERVISOR="VirtualBox" ;;
        3) DEFAULT_HYPERVISOR="UTM" ;;
        *) echo "[setup.sh] Invalid answer."; exit 1
    esac
    echo "DEFAULT_HYPERVISOR=$DEFAULT_HYPERVISOR" > "$CONFIG_FILE"
fi

install_ansible() {
    echo "[setup.sh] Ansible is not installed. Attempting an install..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y ansible
    elif command -v brew &>/dev/null; then
        brew install ansible
    elif command -v pacman &>/dev/null; then
        sudo pacman -S ansible
    elif command -v dnf &>/dev/null; then
        sudo dnf install ansible
    elif command -v zypper &>/dev/null; then
        sudo zypper install ansible
    else
        echo "[setup.sh] No viable Ansible installation method. Quitting..."
        exit 1
    fi
}

if ! command -v ansible &>/dev/null; then
    echo "[setup.sh] Ansible not found. Attempting installation..."
    install_ansible
fi

if [[ "$DEFAULT_HYPERVISOR" == "VirtualBox" ]]; then
    if ! command -v VBoxManage &>/dev/null; then
        echo "[setup.sh] VirtualBox not found. Please install VirtualBox."
        if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "msys" ]]; then
            echo "[setup.sh] Install VirtualBox from: https://www.virtualbox.org/"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo "[setup.sh] On macOS, please install UTM instead of VirtualBox."
        fi
        exit 1
    fi
elif [[ "$DEFAULT_HYPERVISOR" == "utm" ]]; then
    if ! command -v utmctl &>/dev/null; then
        echo "[setup.sh] UTM not found. Please install UTM on macOS."
        exit 1
    fi
elif [[ "$DEFAULT_HYPERVISOR" == "qemu" ]]; then
    if ! command -v qemu-system-x86_64 &>/dev/null; then
        echo "[setup.sh] QEMU not found. Please install QEMU."
        exit 1
    fi
fi

if [[ "$ARCH" == "x86_64" ]]; then
    ISO_URL="https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    ISO_URL="https://repo.almalinux.org/almalinux/9/isos/aarch64/AlmaLinux-9-latest-aarch64-dvd.iso"
else
    echo "[setup.sh] Unsupported arch: $ARCH"; exit 1
fi

if [[ ! -f "$ISO_PATH" ]]; then
    read -rp "[setup.sh] ISO not found. Download AlmaLinux 9 for $ARCH? (y/N) " yn
    case "$yn" in
        [Yy]*) curl -L -o "$ISO_PATH" "$ISO_URL" ;;
        *) echo "[setup.sh] Need ISO but not allowed to download nor does the file exist. Aborting."; exit 1 ;;
    esac
fi

if [[ "$DEFAULT_HYPERVISOR" == "QEMU" ]]; then
    [[ -f alma9_disk.qcow2 ]] || qemu-img create -f qcow2 "$VM_NAME.qcow2" 10G
    qemu-system-x86_64 \
      -m 2048 -smp 2 \
      -cdrom "$ISO_PATH" \
      -drive file=alma9_disk.qcow2,if=virtio \
      -boot d \
      -netdev user,id=net0 \
      -device virtio-net-pci,netdev=net0 \
    exit 0
fi

if [[ "$DEFAULT_HYPERVISOR" == "VirtualBox" ]]; then
    VBoxManage list vms | grep "\"$VM_NAME\"" || {
        VBoxManage createvm --name "$VM_NAME" --register
        VBoxManage modifyvm "$VM_NAME" --memory 2048 --acpi on --boot1 dvd --ostype RedHat_64 --ioapic on --cpus 2
        VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci
        VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"
        VBoxManage createhd --filename "${VM_NAME}_disk.vdi" --size 10000
        VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 1 --device 0 --type hdd --medium "${VM_NAME}_disk.vdi"
        VBoxManage modifyvm "$VM_NAME" --nic1 nat --nictype1 virtio --cableconnected1 on
    }
    VBoxManage startvm "$VM_NAME" --type headless
    echo "[setup.sh] Waiting 30s for boot..."
    sleep 30
    IP=$(VBoxManage guestproperty get "$VM_NAME" "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{print $2}')
elif [[ "$DEFAULT_HYPERVISOR" == "UTM" ]]; then
    echo "[setup.sh] Calling AppleScript, here goes nothing..."
    # fix for -euo pipefail
    osascript utm-handler.scpt "$ARCH" "$VM_NAME" "$ISO_PATH" &>/dev/null || true
    if [ $? -eq 0 ]; then
	echo "[setup.sh] VM already exists!"
    else
	echo "[setup.sh] VM exists now. Start it at your leisure."
	echo "UTM_INSTALLED=1" >> "$CONFIG_FILE"
    fi
    echo "[setup.sh] Currently, there's no easy IP detection for UTM, sorry."
    echo "[setup.sh] Check the settings for your VM and find what this is, or run the \"ip a\" command."
    IP="unknown"
else
    echo "[setup.sh] No VM manager found."
    echo "[setup.sh] Try checking your \$PATH?"
    exit 1
fi

echo "[alma9]" >> inventory.ini
# TODO: this is terrible.
echo "$IP ansible_user=root ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory.ini 
echo "[setup.sh] Inventory written to inventory.ini. Edit that file if you use UTM; SSH into that IP address."
echo "[setup.sh] To reset this setup, delete setup-data."
