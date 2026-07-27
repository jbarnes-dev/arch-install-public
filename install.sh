#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if (( EUID == 0 )); then
    printf 'Run this script as the desktop user, not as root.\n' >&2
    exit 1
fi

if ! command -v pacman >/dev/null; then
    printf 'This installer is intended for Arch Linux.\n' >&2
    exit 1
fi

source "$REPO_DIR/scripts/lib.sh"

log 'Installing official repository packages'
"$REPO_DIR/scripts/install-packages.sh"

log 'Installing yay and AUR packages'
"$REPO_DIR/scripts/install-aur.sh"

log 'Writing user configuration'
"$REPO_DIR/scripts/configure-user.sh"

log 'Enabling NetworkManager'
sudo systemctl enable --now NetworkManager.service

log 'Installation complete. Start a new login session to use the new configuration.'
