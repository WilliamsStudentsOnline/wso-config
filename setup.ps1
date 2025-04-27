##### WSO-Config WSO 2.0 #####
$ErrorActionPreference = "Stop"

$configFile = "$PWD\.setup-data"
$defaultHypervisor = ""
$isoName = "AlmaLinux-9.5-$arch.iso"
$arch = (Get-CimInstance Win32_Processor).Architecture

# we should not run on anything but Windows,
# the other script is for Unix hosts.
if ($IsWindows -or $ENV:OS) {
    Write-Host "[setup.ps1] This is the Windows setup script. Do not run this on WSL!"
} else {
    Write-Error "[setup.ps1] Don't run this script in portable versions of PowerShell!"
}

switch ($arch) {
    9 { $archString = "arm64" }
    0 { $archString = "x86_64" }
    default { Write-Error "[setup.ps1] Unsupported architecture: $arch"; exit 1 }
}

$isoPath = Join-Path $PWD $isoName
$vmName = "AlmaLinux-WSO"

if (Test-Path $configFile) {
    . $configFile
} else {
    Write-Host "[setup.ps1] Choose your hypervisor:"
    Write-Host "1) QEMU"
    Write-Host "2) VirtualBox"
    $hvSel = Read-Host "[setup.ps1] Selection [1-2]: "
    switch ($hvSel) {
        "1" { $defaultHypervisor = "QEMU" }
        "2" { $defaultHypervisor = "VirtualBox" }
        default { Write-Error "[setup.ps1] invalid answer."; exit 1 }
    }
    "DEFAULT_HYPERVISOR=`"$defaultHypervisor`"" | Set-Content $configFile
}

function Install-Ansible {
    Write-Host "[setup.ps1] Trying to install Ansible..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
	Write-Host "[setup.ps1] Please approve the installation on the next prompt."
        winget install --id RedHat.Ansible -e
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
	Write-Host "[setup.ps1] Please approve the installation on the next prompt."
        choco install ansible
    } else {
        Write-Error "[setup.ps1] No package manager found. Install winget or choco, or install Ansible manually."
        exit 1
    }
}

if (-not (Get-Command ansible -ErrorAction SilentlyContinue)) {
    Install-Ansible
}

if ($defaultHypervisor -eq "VirtualBox") {
    if (-not (Get-Command VBoxManage -ErrorAction SilentlyContinue)) {
        Write-Error "[setup.ps1] VirtualBox not found. Install it from https://www.virtualbox.org/"
        exit 1
    }
} elseif ($defaultHypervisor -eq "QEMU") {
    if (-not (Get-Command qemu-system-x86_64 -ErrorAction SilentlyContinue)) {
        Write-Error "[setup.ps1] QEMU not found. Install it via choco or manually."
        exit 1
    }
}

switch ($archString) {
    "x86_64" { $isoUrl = "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso" }
    "arm64" { $isoUrl = "https://repo.almalinux.org/almalinux/9/isos/aarch64/AlmaLinux-9-latest-aarch64-dvd.iso" }
    default { Write-Error "[setup.ps1] Unsupported arch: $archString"; exit 1 }
}

if (-not (Test-Path $isoPath)) {
    $yn = Read-Host "[setup.ps1] ISO not found. Download AlmaLinux 9.5 for $archString? (y/N)"
    if ($yn -match '^[Yy]$') {
        Invoke-WebRequest -Uri $isoUrl -OutFile $isoPath
    } else {
        Write-Error "[setup.ps1] Need ISO but download not approved. Quitting."
        exit 1
    }
}

if ($defaultHypervisor -eq "QEMU") {
    Write-Host "[setup.ps1] Making VM if it doesn't exist, then booting..."
    if (-not (Test-Path "alma9_disk.qcow2")) {
        qemu-img create -f qcow2 "$vmName.qcow2" 10G
    }
    qemu-system-x86_64 `
      -m 2048 -smp 2 `
      -cdrom $isoPath `
      -drive file=alma9_disk.qcow2,if=virtio `
      -boot d `
      -netdev user,id=net0 `
      -device virtio-net-pci,netdev=net0
    exit 0
}

if ($defaultHypervisor -eq "VirtualBox") {
    Write-Host "[setup.ps1] Making VM if it doesn't exist, then booting..."
    $vms = VBoxManage list vms
    if ($vms -notmatch $vmName) {
        VBoxManage createvm --name $vmName --register
        VBoxManage modifyvm $vmName --memory 2048 --acpi on --boot1 dvd --ostype RedHat_64 --ioapic on --cpus 2
        VBoxManage storagectl $vmName --name "SATA" --add sata --controller IntelAhci
        VBoxManage storageattach $vmName --storagectl "SATA" --port 0 --device 0 --type dvddrive --medium $isoPath
        VBoxManage createhd --filename "${vmName}_disk.vdi" --size 10000
        VBoxManage storageattach $vmName --storagectl "SATA" --port 1 --device 0 --type hdd --medium "${vmName}_disk.vdi"
        VBoxManage modifyvm $vmName --nic1 nat --nictype1 virtio --cableconnected1 on
    }
    VBoxManage startvm $vmName --type headless
    Start-Sleep -Seconds 30
    # TODO: probably buggy as hell
    $ipResult = VBoxManage guestproperty get $vmName "/VirtualBox/GuestInfo/Net/0/V4/IP"
    $ip = ($ipResult -split ' ')[-1]
    Write-Host "[setup.ps1] We have made a best guess attempt at determining your IP address for the VM. You may wish to change this manually, since it is a known bug that VirtualBox may return the wrong one, especially if you have many VMs or have one active while this script was running."
}

"[alma9]" | Out-File -Append inventory.ini
"$ip ansible_user=root ansible_ssh_common_args='-o StrictHostKeyChecking=no'" | Out-File -Append inventory.ini
Write-Host "[setup.ps1] Inventory written to inventory.ini. SSH into that IP address."
Write-Host "[setup.ps1] Delete .setup-data to reset."
