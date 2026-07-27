#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/scripts/lib.sh"

install -d \
    "$HOME/.config/i3" \
    "$HOME/.config/picom" \
    "$HOME/.config/polybar" \
    "$HOME/.config/rofi" \
    "$HOME/.config/gtk-3.0" \
    "$HOME/.config/gtk-4.0" \
    "$HOME/.vim/colors" \
    "$HOME/Pictures"

for file in .bash_profile .bashrc .vimrc .xinitrc .Xresources; do
    backup_file "$HOME/$file"
done

cat > "$HOME/.bash_profile" <<'EOF'
[[ -f ~/.bashrc ]] && source ~/.bashrc

if [[ -z ${DISPLAY:-} && $(tty) == /dev/tty1 ]]; then
    exec startx
fi
EOF

cat > "$HOME/.bashrc" <<'EOF'
[[ $- == *i* ]] || return

alias ls='ls --color=auto'
alias ll='ls -alF'
PS1='[\u@\h \W]\$ '
EOF

cat > "$HOME/.vimrc" <<'EOF'
set nocompatible
filetype plugin indent on
syntax enable
set hidden wildmenu showcmd hlsearch
set ignorecase smartcase
set backspace=indent,eol,start
set autoindent number ruler laststatus=2 confirm
set mouse=a
set shiftwidth=4 softtabstop=4 expandtab
set undofile
set directory^=$HOME/.cache/vim/swap//
set undodir=$HOME/.cache/vim/undo//
silent !mkdir -p ~/.cache/vim/swap ~/.cache/vim/undo
nnoremap <C-L> :nohlsearch<CR><C-L>
EOF

cat > "$HOME/.xinitrc" <<'EOF'
#!/bin/sh
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
eval "$(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)"
export SSH_AUTH_SOCK
exec i3
EOF

cat > "$HOME/.Xresources" <<'EOF'
URxvt.font: xft:RobotoMono Nerd Font:size=10
URxvt.termName: rxvt-unicode-256color
URxvt.scrollBar: false
URxvt.perl-ext-common: default,matcher
URxvt.url-launcher: /usr/bin/xdg-open
URxvt.matcher.button: 1
URxvt.foreground: #ffffff
URxvt.background: rgba:0000/0000/0000/cccc
Xft.dpi: 96
Xft.antialias: true
Xft.hinting: true
Xft.hintstyle: hintfull
EOF

cat > "$HOME/.config/rofi/config.rasi" <<'EOF'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    font: "RobotoMono Nerd Font 14";
}
@theme "gruvbox-dark-hard"
EOF

cat > "$HOME/.config/picom/picom.conf" <<'EOF'
backend = "glx";
vsync = true;
shadow = true;
shadow-radius = 12;
shadow-offset-x = -12;
shadow-offset-y = -8;
shadow-opacity = 0.5;
shadow-exclude = [ "class_g = 'Polybar'" ];
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
corner-radius = 0;
EOF

cat > "$HOME/.config/polybar/config.ini" <<'EOF'
[colors]
background = #e6000000
foreground = #ffffff
primary = #6d938f
alert = #bd2c40

[bar/main]
width = 100%
height = 35
background = ${colors.background}
foreground = ${colors.foreground}
line-size = 3
padding-left = 1
padding-right = 1
module-margin = 1
font-0 = RobotoMono Nerd Font:size=11;2
modules-left = filesystem cpu memory temperature
modules-center = i3
modules-right = pulseaudio wlan eth battery date
cursor-click = pointer
enable-ipc = true

[module/i3]
type = internal/i3
pin-workspaces = true
label-focused = %index%
label-focused-background = ${colors.primary}
label-focused-padding = 2
label-unfocused = %index%
label-unfocused-padding = 2
label-visible = %index%
label-visible-padding = 2
label-urgent = %index%!
label-urgent-background = ${colors.alert}
label-urgent-padding = 2

[module/filesystem]
type = internal/fs
mount-0 = /
interval = 25
label-mounted = %mountpoint%: %free%/%total%

[module/cpu]
type = internal/cpu
interval = 2
label = CPU %percentage%%

[module/memory]
type = internal/memory
interval = 2
label = RAM %percentage_used%%

[module/temperature]
type = internal/temperature
thermal-zone = 0
warn-temperature = 80
label = %temperature-c%
label-warn = %temperature-c%
label-warn-foreground = ${colors.alert}

[module/pulseaudio]
type = internal/pulseaudio
label-volume = VOL %percentage%%
label-muted = MUTED

[module/wlan]
type = internal/network
interface-type = wireless
interval = 3
label-connected = %essid% %local_ip%
label-disconnected =

[module/eth]
type = internal/network
interface-type = wired
interval = 3
label-connected = %local_ip%
label-disconnected =

[module/battery]
type = internal/battery
battery = BAT0
adapter = AC
poll-interval = 5
label-charging = CHG %percentage%%
label-discharging = BAT %percentage%%
label-full = BAT full

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d
time = %H:%M
label = %date% %time%
EOF

cat > "$HOME/.config/polybar/launch.sh" <<'EOF'
#!/usr/bin/env bash
polybar-msg cmd quit >/dev/null 2>&1 || true
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

if command -v xrandr >/dev/null; then
    while IFS= read -r monitor; do
        MONITOR="$monitor" polybar --reload main &
    done < <(xrandr --query | awk '/ connected/{print $1}')
else
    polybar --reload main &
fi
EOF
chmod +x "$HOME/.config/polybar/launch.sh"

cat > "$HOME/.config/i3/config" <<'EOF'
set $mod Mod4
font pango:RobotoMono Nerd Font 9
floating_modifier $mod

bindsym $mod+Return exec i3-sensible-terminal
bindsym $mod+d exec rofi -show drun
bindsym $mod+space exec rofi -show run
bindsym $mod+l exec betterlockscreen -l
bindsym $mod+Shift+q kill
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec i3-msg exit
bindsym $mod+f fullscreen toggle
bindsym $mod+Shift+space floating toggle
bindsym $mod+h split h
bindsym $mod+v split v
bindsym $mod+e layout toggle split

bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

mode "resize" {
    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

gaps inner 10
gaps outer 8
default_border pixel 2
client.focused #6d938f #6d938f #ffffff #6d938f #6d938f

exec_always --no-startup-id ~/.config/polybar/launch.sh
exec --no-startup-id xrdb -merge ~/.Xresources
exec --no-startup-id xset r rate 300 80
exec --no-startup-id feh --bg-fill ~/Pictures/ww_lightning_tree_may2023.jpg
exec --no-startup-id nm-applet
exec --no-startup-id dunst
exec --no-startup-id blueman-applet
exec --no-startup-id picom --config ~/.config/picom/picom.conf
exec --no-startup-id udiskie --tray
exec --no-startup-id xfce4-power-manager
EOF

gtk_theme=
for theme_dir in \
    /usr/share/themes/vimix-dark-ruby/gtk-4.0 \
    /usr/share/themes/vimix-dark-beryl/gtk-4.0 \
    /usr/share/themes/vimix-dark-*/gtk-4.0; do
    if [[ -d $theme_dir/assets &&
        -f $theme_dir/gtk.css &&
        -f $theme_dir/gtk-dark.css ]]; then
        gtk_theme=${theme_dir%/gtk-4.0}
        gtk_theme=${gtk_theme##*/}
        break
    fi
done
[[ -n $gtk_theme ]] ||
    die 'No complete Vimix dark GTK 4 theme was found in /usr/share/themes'

cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=vimix
gtk-font-name=Cantarell 11
gtk-cursor-theme-name=Adwaita
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
EOF

cat > "$HOME/.config/gtk-3.0/gtk.css" <<'EOF'
.window-frame, .window-frame:backdrop {
    box-shadow: 0 0 0 black;
    border-style: none;
    margin: 0;
    border-radius: 0;
}
.titlebar { border-radius: 0; }
EOF

# Libadwaita does not read the GTK 3 theme setting. Link the matching GTK 4
# assets into the per-user configuration so GTK 4 applications use Vimix too.
readonly GTK4_THEME_DIR="/usr/share/themes/$gtk_theme/gtk-4.0"
for theme_file in assets gtk.css gtk-dark.css; do
    theme_target="$HOME/.config/gtk-4.0/$theme_file"
    backup_file "$theme_target"
    ln -sfnT "$GTK4_THEME_DIR/$theme_file" "$theme_target"
done

find "$REPO_DIR/homestuff/Pictures" -maxdepth 1 -type f -exec cp -n -- {} "$HOME/Pictures/" \;

printf 'User configuration written to %s\n' "$HOME"
