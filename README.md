# JupyterPicoSDK

*Rapidly develop, build, and flash Raspberry Pi Pico firmware directly within Jupyter.*

---

## Overview

**JupyterPicoSDK** streamlines the development workflow for Raspberry Pi Pico (RP2040) projects, enabling you to write, compile, flash, and debug firmware entirely from a single Jupyter notebook. This tool eliminates the complexity and manual steps traditionally associated with embedded firmware development, making it ideal for rapid prototyping, education, and well-documented experimentation.

---

## Key Benefits

* **Integrated Workflow:** Write, compile, flash, and debug without leaving Jupyter.
* **Cross-Platform Compatibility:** Supports macOS, Ubuntu, Fedora, Arch, Manjaro, and Windows (native and WSL2).
* **Reproducible Builds:** Utilizes Docker containers ensuring consistent, isolated build environments.
* **Automatic Flashing:** Automatically detects and flashes your Raspberry Pi Pico without manual intervention.
* **Real-Time Logging:** Instantly view USB-CDC output within notebook cells.
* **Easy Setup:** Comprehensive installation scripts provided for quick environment setup.

---

## Features

| Feature                     | Description                                                                                           |
| --------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Cross-Platform**          | macOS 12+, Ubuntu 22.04+, Fedora 39+, Arch/Manjaro, Windows 10/11 (native or WSL2).                   |
| **Containerized Builds**    | Uses `ghcr.io/nu-horizonsat/pico-sdk-docker` container with official Pico SDK and ARM cross-compiler. |
| **Automated Flashing**      | Utilizes `picotool` to automatically flash UF2 files to the RP2040 without manual BOOTSEL mode entry. |
| **Kernel Integration**      | Jupyter kernel integration for streamlined notebook operation.                                        |
| **Simplified Installation** | Turn-key installers via Bash (Linux/macOS) and PowerShell (Windows).                                  |
| **Standardized Project**    | Modern Python packaging (PEP 517 compliant, `pyproject.toml`, PyPI deployment).                       |

---

## Quick Start Guide

### Requirements

| Component      | macOS / Linux                    | Windows                           |
| -------------- | -------------------------------- | --------------------------------- |
| Python ≥ 3.9   | ✅                                | ✅                                 |
| Docker ≥ 20.10 | Docker Desktop or distro package | Docker Desktop (WSL2 backend)     |
| Node.js LTS    | Installed via provided script    | Installed via provided script     |
| USB driver     | Not required                     | Automatically installed via Zadig |

> **WSL2 Users:** If using Windows with WSL2 and Ubuntu, run the Linux installer within WSL2 and forward USB via `usbipd-win`.

### Installation

#### macOS / Linux

```bash
git clone https://github.com/dankeg/JupyterPicoSDK
cd JupyterPicoSDK
./install_dependencies.sh          # Installs Docker, picotool, Python dependencies
source .venv/bin/activate          # Activate virtual environment
pico-sdk-install-kernel            # Registers Jupyter kernel
```

#### Windows (PowerShell 7)

```powershell
git clone https://github.com/dankeg/JupyterPicoSDK
cd JupyterPicoSDK
Set-ExecutionPolicy Bypass -Scope Process -Force
./install_dependencies.ps1         # Run once with admin rights
pico-sdk-install-kernel            # Registers Jupyter kernel
```

After installation, launch **Jupyter Lab** and select **Kernel → Pico SDK**.

---

## Example: Your First Program

```c
// %% main.c – Jupyter writes this content to main.c automatically
#include <stdio.h>
#include "pico/stdlib.h"

int main() {
    stdio_init_all();
    while (true) {
        printf("Hello, Jupyter!\n");
        sleep_ms(1000);
    }
    return 0;
}
```

Run this notebook cell. You will see compilation output, automatic flashing to your Pico, and real-time output directly in Jupyter.

---

## Technical Details

### Workflow Diagram

```
┌─────────────────┐        devcontainer up        ┌────────────────────────┐
│  Jupyter Cell   │──────────────────────────────▶│ pico-sdk Docker Image  │
└─────────────────┘      (build_code.sh)          │ • arm-none-eabi-gcc    │
        │                                         │ • CMake + Pico SDK     │
        │ UF2              ┌─────────┐            └──────────┬─────────────┘
        └─────────────────▶│ picotool│──flash─────▶│   Raspberry Pi Pico   │
          (load_code.sh)   └─────────┘              └───────────┬───────────┘
                                                       USB CDC output ↩
```

* `kernel.py` manages interaction and logging.
* Docker ensures isolation and clean PATH.
* Helper scripts included within kernelspec ensure portability.

---

## Developer Guide

```bash
pip install -e .[dev]   # Install for development, includes formatting/linting
pytest -q               # Execute tests
pre-commit install      # Automatic formatting on commit
```

### Publishing Updates

```bash
python -m build

# Publish to PyPI
twine upload dist/*
```

---

## Troubleshooting

| Issue                              | Solution                                                                                          |              |
| ---------------------------------- | ------------------------------------------------------------------------------------------------- | ------------ |
| Kernel not listed                  | Run `pico-sdk-install-kernel` and restart JupyterLab.                                             |              |
| picotool not detecting board       | Ensure Pico is in BOOTSEL mode and use data-capable USB cable. Check device presence with \`lsusb | grep 2e8a\`. |
| Permission errors on serial device | Re-plug Pico or reload udev rules (`sudo udevadm trigger`).                                       |              |
| Docker permission denied           | Re-login to session or run `newgrp docker`.                                                       |              |

---