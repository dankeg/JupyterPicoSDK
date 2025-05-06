#!/usr/bin/env bash
#
# install_dependencies.sh ─ one‑shot bootstrapper for the
# Jupyter‑PicoSDK kernel (Python + toolchain + Docker + picotool).
#
# Supported distros     macOS 12+  |  Ubuntu 22.04+  |  Debian 12+
#                       Fedora 39+ |  Arch / Manjaro
#
# Usage:
#     chmod +x install_dependencies.sh
#     ./install_dependencies.sh
#
set -euo pipefail

#───────────────────────────────────────────────────────────────────────────────
# 0. Helper
#───────────────────────────────────────────────────────────────────────────────
need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌  '$1' not found – the install seems to have failed." >&2
    exit 1
  fi
}

#───────────────────────────────────────────────────────────────────────────────
# 1. Detect platform
#───────────────────────────────────────────────────────────────────────────────
OS="$(uname -s)"
PKG_MANAGER=""
DOCKER_SERVICE=""

if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="mac"
elif [[ "$OS" == "Linux" ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    case "${ID_LIKE:-$ID}" in
        *debian*)
            PLATFORM="debian"
            ;;
        *fedora*|*rhel*)
            PLATFORM="fedora"
            ;;
        *arch*)
            PLATFORM="arch"
            ;;
        *)
            echo "❌ Unsupported Linux distribution ($PRETTY_NAME)."
            exit 1
            ;;
    esac
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

#───────────────────────────────────────────────────────────────────────────────
# 2. Install system packages
#───────────────────────────────────────────────────────────────────────────────
echo "▶ Installing core packages for $PLATFORM …"

if [[ "$PLATFORM" == "mac" ]]; then
    # Homebrew – install if needed
    if ! command -v brew >/dev/null 2>&1; then
        echo "→ Homebrew not found; installing…"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    brew update

    brew install python@3.12 cmake libusb git picotool \
                 node docker-compose
    brew install --cask docker        # Docker Desktop GUI

    # gcc‑arm‑none‑eabi from ARM tap (needed for local builds outside the container)
    brew tap ArmMbed/homebrew-formulae
    brew install arm-none-eabi-gcc

elif [[ "$PLATFORM" == "debian" ]]; then
    sudo apt-get update
    sudo apt-get install -y \
        python3 python3-pip python3-venv \
        build-essential cmake git curl wget \
        gcc-arm-none-eabi binutils-arm-none-eabi \
        libnewlib-arm-none-eabi libusb-1.0-0-dev \
        docker.io \
        nodejs npm \
        picotool

    DOCKER_SERVICE="docker"

elif [[ "$PLATFORM" == "fedora" ]]; then
    sudo dnf -y update
    sudo dnf -y install \
        python3 python3-pip python3-virtualenv \
        cmake git libusb1-devel make gcc-c++ \
        arm-none-eabi-gcc-cs arm-none-eabi-binutils-cs arm-none-eabi-newlib \
        docker docker-compose \
        nodejs npm \
        picotool

    DOCKER_SERVICE="docker"

elif [[ "$PLATFORM" == "arch" ]]; then
    sudo pacman -Sy --needed --noconfirm \
        python python-pip python-virtualenv \
        cmake git libusb make base-devel \
        arm-none-eabi-gcc arm-none-eabi-binutils arm-none-eabi-newlib \
        docker docker-compose \
        nodejs npm \
        picotool

    DOCKER_SERVICE="docker"
fi

#───────────────────────────────────────────────────────────────────────────────
# 3. Enable Docker (Linux)
#───────────────────────────────────────────────────────────────────────────────
if [[ "$OS" == "Linux" ]]; then
    echo "▶ Setting up Docker…"
    sudo systemctl enable --now "$DOCKER_SERVICE"
    sudo usermod -aG docker "$USER"
fi

#───────────────────────────────────────────────────────────────────────────────
# 4. Install devcontainer‑cli globally (used by build_code.sh)
#───────────────────────────────────────────────────────────────────────────────
if ! command -v devcontainer >/dev/null 2>&1; then
    echo "▶ Installing devcontainer‑cli …"
    sudo npm install -g @devcontainers/cli
fi

#───────────────────────────────────────────────────────────────────────────────
# 5. Python virtual environment + kernel registration
#───────────────────────────────────────────────────────────────────────────────
echo "▶ Creating Python virtual environment (.venv)…"
python3 -m venv .venv
# shellcheck source=/dev/null
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install -e .
python -m ipykernel install --user --name pico_kernel --display-name "Pico SDK"

#───────────────────────────────────────────────────────────────────────────────
# 6. udev rule for the Pico (Linux only)
#───────────────────────────────────────────────────────────────────────────────
if [[ "$OS" == "Linux" ]]; then
    echo "▶ Installing udev rule so the Pico can be flashed without sudo…"
    UDEV_FILE="/etc/udev/rules.d/99-pico.rules"
    RULE='SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", MODE="0666"'
    if [[ ! -f $UDEV_FILE ]]; then
        echo "$RULE" | sudo tee "$UDEV_FILE" >/dev/null
        sudo udevadm control --reload-rules
        sudo udevadm trigger
    fi
fi

#───────────────────────────────────────────────────────────────────────────────
# 7. Final sanity checks
#───────────────────────────────────────────────────────────────────────────────
echo "▶ Verifying installation…"
for cmd in python3 picotool docker devcontainer cmake; do
  need "$cmd"
done

echo
echo "✅  All dependencies installed!"
if [[ "$OS" == "Linux" ]]; then
    echo "   → Log out & back in (or run 'newgrp docker') so your user gains Docker permissions."
    echo "   → Plug in your Pico – it should enumerate as /dev/ttyACM* without sudo."
else
    echo "   → Start Docker Desktop before using the kernel."
fi
