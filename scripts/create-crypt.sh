#!/bin/bash

PART=$1
TMPMOUNT=create-crypt-usb-mount

question() {
    local ANS
    until [[ $ANS =~ ^[YyNn]$ ]]; do
        read -p "$1?  [y/N] " -n 1 -r ANS
        echo
    done
    [[ $ANS =~ ^[Yy]$ ]] && return 0 || return 1
}

if question "Overwrite with random bytes"; then
    echo Overwriting with random bytes
    sudo dd if=/dev/urandom bs=1M of="$PART" status=progress
fi

echo Running luksFormat
sudo cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 -y "$PART"

echo Running luksOpen
sudo cryptsetup luksOpen "$PART" "$TMPMOUNT"

echo Creating ext4 filesystem
sudo mkfs.ext4 "/dev/mapper/$TMPMOUNT"

echo Running luksClose
sudo cryptsetup luksClose $TMPMOUNT

