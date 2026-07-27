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
    local theme_dir

    pacman -Qq "$package" >/dev/null 2>&1 || return 1

    # Check payload that this installer actually consumes. A package can
    # intentionally register paths that are generated or removed at runtime,
    # so treating every absent pacman manifest entry as corruption is too
    # aggressive.
    case $package in
        vimix-gtk-themes-git)
            for theme_dir in \
                /usr/share/themes/Vimix-dark-*/gtk-4.0 \
                /usr/share/themes/vimix-dark-*/gtk-4.0; do
                if [[ -d $theme_dir/assets &&
                    -f $theme_dir/gtk.css &&
                    -f $theme_dir/gtk-dark.css ]]; then
                    return 0
                fi
            done
            return 1
            ;;
        *)
            return 0
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
    printf 'Clean-rebuilding AUR packages with missing required files: %s\n' \
        "${broken_packages[*]}"
    yay -S --rebuild --answerclean All "${broken_packages[@]}"

    for package in "${broken_packages[@]}"; do
        package_payload_intact "$package" || {
            printf 'error: %s still has missing files after reinstall\n' \
                "$package" >&2
            if [[ $package == vimix-gtk-themes-git ]]; then
                printf 'GTK 4 theme directories actually installed:\n' >&2
                find /usr/share/themes -mindepth 2 -maxdepth 2 \
                    -type d -name gtk-4.0 -print 2>/dev/null >&2
            fi
            exit 1
        }
    done
fi
