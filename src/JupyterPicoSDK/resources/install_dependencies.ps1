<#
.SYNOPSIS
    Installs all external dependencies for the Jupyter‑PicoSDK kernel on
    Windows 10/11 using winget (preferred) or Chocolatey (fallback).

.DESCRIPTION
    The script installs:
      • Python 3.x (if missing)
      • Git, CMake, GNU Arm Embedded Tool‑chain
      • Node LTS + devcontainer CLI
      • Docker Desktop (WSL‑2 backend)
      • Prebuilt picotool.exe (latest GitHub release) into %USERPROFILE%\.pico\bin
      • Registers the Pico SDK Jupyter kernel

    It MUST be run from an elevated PowerShell (Run as Administrator) once,
    then you can launch Jupyter from a normal shell.
#>

#region 0. helpers
function Test-Command { param($Name) return @(Get-Command $Name -ErrorAction SilentlyContinue).Count -gt 0 }
function Need($Name) { if (-not (Test-Command $Name)) { Write-Error "'$Name' is still missing – installation failed."; exit 1 } }
#endregion

#region 1. Winget / Chocolatey detection
if (Test-Command "winget") {
    $installer = "winget"
    Write-Host  "▶ Using winget to install packages..."
    $WingetArgs = @{Source="winget"; Exact=$true; AcceptPackageAgreements=$true; AcceptSourceAgreements=$true}
}
elseif (Test-Command "choco") {
    $installer = "choco"
    Write-Host  "▶ Using Chocolatey to install packages..."
}
else {
    Write-Host "⚠ Neither winget nor Chocolatey found. Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $installer = "choco"
}

#endregion

#region 2. Core packages
switch ($installer) {
    "winget" {
        winget install "Python.Python.3.12" @WingetArgs
        winget install "Git.Git"            @WingetArgs
        winget install "Kitware.CMake"      @WingetArgs
        winget install "ARM.GNUArmEmbeddedToolchain" @WingetArgs
        winget install "OpenJS.NodeJS.LTS"  @WingetArgs
        winget install "Docker.DockerDesktop" @WingetArgs
    }
    "choco" {
        choco install -y python git cmake gcc-arm-embedded nodejs-lts docker-desktop
    }
}

# reload PATH for the current session
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path","User")

#endregion

#region 3. devcontainer CLI (npm global)
if (-not (Test-Command "devcontainer")) {
    npm install -g @devcontainers/cli
    refreshenv | Out-Null  # Chocolatey helper; harmless on winget systems
}

#endregion

#region 4. picotool.exe setup
$picoBin = "$env:USERPROFILE\.pico\bin"
New-Item -ItemType Directory -Force -Path $picoBin | Out-Null

if (-not (Test-Path "$picoBin\picotool.exe")) {
    Write-Host "▶ Downloading pre‑built picotool.exe ..."
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/raspberrypi/picotool/releases/latest"
    $asset   = $release.assets | Where-Object { $_.name -match "picotool.*win.*\.zip" } | Select-Object -First 1
    if (-not $asset) { Write-Error "No Windows binary found in latest release. Aborting."; exit 1 }
    $zipPath = "$env:TEMP\picotool.zip"
    Invoke-WebRequest $asset.browser_download_url -OutFile $zipPath
    Expand-Archive $zipPath -DestinationPath $picoBin -Force
    Remove-Item $zipPath
}
# add to PATH (user scope)
$oldPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($oldPath -notlike "*\.pico\bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$oldPath;$picoBin", "User")
    $env:Path += ";$picoBin"
}

#endregion

#region 5. Zadig (WinUSB driver)
if (-not (Get-Command "zadig" -ErrorAction SilentlyContinue)) {
    Write-Host "▶ Downloading Zadig for WinUSB driver install..."
    $zadigUrl = "https://zadig.akeo.ie/downloads/zadig_2.8.exe"
    $zadigExe = "$env:TEMP\zadig.exe"
    Invoke-WebRequest $zadigUrl -OutFile $zadigExe
}
Write-Host "ℹ  A Pico must use the WinUSB driver for picotool. After you plug a Pico into BOOTSEL mode, run:"
Write-Host "      $zadigExe"
Write-Host "   → Select 'RP2040 USB BOOT', choose WinUSB, click 'Install Driver'."

#endregion

#region 6. Python venv + Jupyter kernel
if (-not (Test-Path ".venv")) {
    python -m venv .venv
}
& ".\.venv\Scripts\Activate.ps1"
python -m pip install -U pip
pip install -r requirements.txt
pip install -e .
python -m ipykernel install --user --name pico_kernel --display-name "Pico SDK"

#endregion

#region 7. Verify
foreach ($cmd in "python","git","cmake","arm-none-eabi-gcc","devcontainer","picotool","docker") {
    Need $cmd
}

Write-Host ""
Write-Host "✅  All Windows dependencies are in place."
Write-Host "   • Start Docker Desktop once and enable WSL 2 integration."
Write-Host "   • Flashing requires the WinUSB driver (see Zadig instructions above)."
Write-Host "   • Open Jupyter and pick the “Pico SDK” kernel!"
#endregion
