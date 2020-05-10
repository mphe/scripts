#!/usr/bin/env bash

question() {
    local ANS
    until [[ $ANS =~ ^[YyNn]$ ]]; do
        read -p "$1?  [y/N] " -n 1 -r ANS
        echo
    done
    [[ $ANS =~ ^[Yy]$ ]] && return 0 || return 1
}

PACKAGES=""

for i in $(pacman -Qsq "$@"); do
    pacman -Qi "$i" | grep -e Name -e Description -e "Optional For" -e "Required By"

    if question "Remove"; then
        REQUIRED="$(pacman -Qi "$i" | grep Required | sed -E 's/Required By\s*:\s*//' | sed -E 's/^\s.*//' | sed -E 's/\s.*$//')"
        if [[ "$REQUIRED" == "None" ]]; then
            REQUIRED=""
        fi
        PACKAGES="$PACKAGES $i $REQUIRED"
    fi

    echo
done

echo "Packages to be removed: $PACKAGES"

sudo pacman -Rs $PACKAGES
