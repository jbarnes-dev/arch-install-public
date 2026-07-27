#!/usr/bin/env bash
set -Eeuo pipefail

readonly BUILD_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/arch-install"

aur_packages=(
    google-chrome
    sublime-text-dev
    vimix-gtk-themes-git
    vimix-icon-theme-git
    eddie-ui
    betterlockscreen
    djvu2pdf
    slack-desktop
)

if ! command -v yay >/dev/null; then
    command -v git >/dev/null || {
        printf 'git is required to bootstrap yay\n' >&2
        exit 1
    }

    mkdir -p "$BUILD_ROOT"
    if [[ -d "$BUILD_ROOT/yay/.git" ]]; then
        git -C "$BUILD_ROOT/yay" pull --ff-only
    else
        git clone https://aur.archlinux.org/yay.git "$BUILD_ROOT/yay"
    fi
    (
        cd "$BUILD_ROOT/yay"
        makepkg -si --needed
    )
fi

yay -S --needed "${aur_packages[@]}"
