#!/usr/bin/env bash

log() {
    printf '\n\033[1;34m==>\033[0m %s\n' "$*"
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

backup_file() {
    local path=$1
    [[ ! -e "$path" || -e "${path}.pre-arch-install" ]] ||
        cp -a -- "$path" "${path}.pre-arch-install"
}
