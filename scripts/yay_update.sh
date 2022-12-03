#!/usr/bin/env bash
# Update AUR packages without aborting after a single failure
# https://github.com/Jguer/yay/issues/848
yay -Quq --aur | xargs -n 1 yay -S --noconfirm

echo
echo
echo "Following packages failed to install:"
yay -Quq --aur
