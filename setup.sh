#!/usr/bin/env bash
##### WSO-Config WSO 2.0 #####

set -euo pipefail

ARCH=$(uname -m)

# weird macOS specific behavior
if [ "$ARCH" == "arm64" ]; then
  ARCH="aarch64"
fi

echo "[setup.sh] This is the macOS/Linux setup script. Do not run this on WSL!"

install_ansible() {
    echo "[setup.sh] Ansible is not installed. Attempting an install..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y ansible
	ansible-galaxy collection install community.general
    elif command -v brew &>/dev/null; then
        brew install ansible
	ansible-galaxy collection install community.general
    elif command -v pacman &>/dev/null; then
        sudo pacman -S ansible
	ansible-galaxy collection install community.general
    elif command -v dnf &>/dev/null; then
        sudo dnf install ansible
	ansible-galaxy collection install community.general
    elif command -v zypper &>/dev/null; then
        sudo zypper install ansible
	ansible-galaxy collection install community.general
    else
	echo "[setup.sh] Couldn't find a package manager even though I tried (maybe you use something weird or your shell is broken?)."
        echo "[setup.sh] No viable Ansible installation method. Quitting..."
        exit 1
    fi
}

download_iso() {
    if [[ "$ARCH" == "x86_64" ]]; then
	ISO_URL="https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10.0-x86_64-minimal.iso"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
	ISO_URL="https://repo.almalinux.org/almalinux/10/isos/aarch64/AlmaLinux-10.0-aarch64-minimal.iso"
    else
	echo "[setup.sh] Unsupported arch: $ARCH"; exit 1
    fi
    
    read -rp "[setup.sh] ISO not found. Download AlmaLinux 10 latest for $ARCH? (y/N) " yn
    case "$yn" in
        [Yy]*) curl -L -o "$PWD/AlmaLinux-10-latest-$ARCH-boot.iso" "$ISO_URL" ;;
        *) echo "[setup.sh] Need ISO but not allowed to download nor does the file exist. Aborting."; exit 1 ;;
    esac
}

if ! command -v ansible &>/dev/null; then
    echo "[setup.sh] Ansible not found. Attempting installation..."
    install_ansible
fi

if [[ ! -f "$PWD/AlmaLinux-10-latest-$ARCH-boot.iso" ]]; then
    download_iso
fi

echo "[setup.sh] Make sure to edit inventory/hosts.ini. That is how Ansible knows what host to contact, and you want to add your VMs to that list so it works."

