#!/usr/bin/env bash
# Update AUR packages without aborting after a single failure
# https://github.com/Jguer/yay/issues/848

# Sudo loop to prevent loosing priviledges during a long running script
# See https://stackoverflow.com/a/30547074
startsudo() {
    sudo -v
    ( while true; do sudo -v; sleep 50; done; ) &
    SUDO_PID="$!"
    trap stopsudo SIGINT SIGTERM
}

stopsudo() {
    kill "$SUDO_PID"
    trap - SIGINT SIGTERM
    sudo -k
}

startsudo
yay -Quq --aur | xargs -n 1 yay -S --noconfirm
echo
echo
echo "Following packages failed to install:"
yay -Quq --aur
stopsudo
