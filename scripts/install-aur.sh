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

package_payload_intact() {
    local package=$1
    local installed_path
    local theme_dir

    pacman -Qq "$package" >/dev/null 2>&1 || return 1

    while IFS= read -r installed_path; do
        if [[ $installed_path == */ ]]; then
            [[ -d $installed_path ]] || return 1
        else
            [[ -e $installed_path || -L $installed_path ]] || return 1
        fi
    done < <(pacman -Qlq "$package")

    # Also check payload required by this installer. This catches an old or
    # incompletely built package whose own manifest never recorded the files.
    case $package in
        vimix-gtk-themes-git)
            for theme_dir in /usr/share/themes/vimix-dark-*/gtk-4.0; do
                if [[ -d $theme_dir/assets &&
                    -f $theme_dir/gtk.css &&
                    -f $theme_dir/gtk-dark.css ]]; then
                    return 0
                fi
            done
            return 1
            ;;
    esac
}

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

# An interrupted upgrade or manual file removal can leave pacman's database
# claiming a package is current even though some of its payload is absent.
# Reinstall only packages whose registered files are incomplete.
broken_packages=()
for package in "${aur_packages[@]}"; do
    if ! package_payload_intact "$package"; then
        broken_packages+=("$package")
    fi
done

if (( ${#broken_packages[@]} )); then
    printf 'Recovering AUR packages with missing files: %s\n' \
        "${broken_packages[*]}"
    yay -S "${broken_packages[@]}"

    for package in "${broken_packages[@]}"; do
        package_payload_intact "$package" || {
            printf 'error: %s still has missing files after reinstall\n' \
                "$package" >&2
            exit 1
        }
    done
fi
