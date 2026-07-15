# --- Configuration ---
$VMName = "NixOServer-Test"
$SwitchName = "External Switch" # Found on your tower host
$VHDPath = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\$VMName.vhdx"
$ISOPath = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\NixOS-Minimal.iso"

# RAM and CPU Headroom (4GB RAM, 8 Cores)
$RAM = 4GB 
$CPU_Cores = 8 
$DiskSize = 20GB

# --- 1. Download NixOS Minimal ISO ---
if (-not (Test-Path $ISOPath)) {
    Write-Host "Downloading latest NixOS Minimal ISO..."
    $NixUrl = "https://channels.nixos.org/nixos-24.05/latest-nixos-minimal-x86_64-linux.iso"
    Invoke-WebRequest -Uri $NixUrl -OutFile $ISOPath
} else {
    Write-Host "ISO already downloaded. Skipping..."
}

# --- 2. Create the Fixed-Size Virtual Hard Disk & Generation 2 VM ---

Write-Host "Creating Fixed-Size VHDX (This might take a minute!)..."
New-VHD -Path $VHDPath -SizeBytes $DiskSize -Fixed

Write-Host "Creating Hyper-V VM..."
New-VM -Name $VMName -MemoryStartupBytes $RAM -Generation 2 -VHDPath $VHDPath -SwitchName $SwitchName

# --- 3. Configure Hardware limits ---
Set-VMProcessor -VMName $VMName -Count $CPU_Cores
# Disable dynamic memory to prevent NixOS OOM lockups during Flake evaluation!
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false

# --- 4. Attach ISO and Configure Boot ---
Add-VMDvdDrive -VMName $VMName -Path $ISOPath
# Turn off Secure Boot so the custom NixOS Linux kernel can boot properly
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

# Set DVD as the first boot device
$DVD = Get-VMDvdDrive -VMName $VMName | Select-Object -First 1
Set-VMFirmware -VMName $VMName -FirstBootDevice $DVD

# --- 5. Power On ---
Write-Host "Starting NixOS... Open your Hyper-V Manager to connect to the console!"
Start-VM -Name $VMName
