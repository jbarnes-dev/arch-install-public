#!/usr/bin/env bash
set -Eeuo pipefail

# Package groups are kept readable so this list is easy to customize.
packages=(
    # Base tooling
    base-devel git wget

    # X11 and i3 desktop
    xorg-server xorg-xinit xorg-xrandr xorg-xrdb xorg-xset
    i3-wm dmenu rofi rxvt-unicode
    picom polybar dunst feh arandr

    # Desktop integration
    networkmanager network-manager-applet
    blueman udiskie gnome-keyring
    xfce4-power-manager brightnessctl
    pipewire pipewire-alsa pipewire-pulse wireplumber
    alsa-utils pavucontrol
    lxappearance gtk3 xdg-utils

    # Fonts
    noto-fonts ttf-roboto-mono-nerd

    # Applications
    firefox discord signal-desktop
    libreoffice-fresh nautilus
    gimp inkscape flameshot
    vlc zathura zathura-pdf-mupdf
    fastfetch htop tmux vim

    # Development and scientific tools
    python python-pip ipython
    python-numpy python-matplotlib python-scipy python-seaborn
    python-statsmodels python-pandas python-pyqt5
    pymol doxygen stress swig
    ghostscript imagemagick

    # TeX Live (the former texlive-core was split into collections)
    texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra
    texlive-fontsrecommended

    # Media codecs
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly

    # Hardware utilities
    acpi_call turbostat
)

sudo pacman -Syu --needed "${packages[@]}"
