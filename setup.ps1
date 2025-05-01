##### WSO-Config WSO 2.0 #####
$ErrorActionPreference = "Stop"

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

$isoName = "AlmaLinux-9.5-$arch-boot.iso"
$isoPath = Join-Path $PWD $isoName

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

function Download-Iso {
    switch ($archString) {
	"x86_64" { $isoUrl = "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso" }
	"arm64" { $isoUrl = "https://repo.almalinux.org/almalinux/9/isos/aarch64/AlmaLinux-9-latest-aarch64-dvd.iso" }
	default { Write-Error "[setup.ps1] Unsupported arch: $archString"; exit 1 }
    }
    $yn = Read-Host "[setup.ps1] ISO not found. Download AlmaLinux 9.5 for $archString? (y/N)"
    if ($yn -match '^[Yy]$') {
        Invoke-WebRequest -Uri $isoUrl -OutFile $isoPath
    } else {
        Write-Error "[setup.ps1]  Need ISO but not allowed to download nor does the file exist. Aborting."
        exit 1
    }
}

if (-not (Get-Command ansible -ErrorAction SilentlyContinue)) {
    Install-Ansible
}

if (-not (Test-Path $isoPath)) {
    Download-Iso
    
}

Write-Host "[setup.sh] Make sure to edit inventory.ini. That is how Ansible knows what host to contact, and you want to add your VMs to that list so it works."
