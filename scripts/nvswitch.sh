#!/usr/bin/env bash

PCISLOT="$(lspci | grep -i nvidia | cut -d ' ' -f 1)"
POWER_CONTROL_FILE="/sys/bus/pci/devices/0000:$PCISLOT/power/control"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
COLOR_RESET="$(tput sgr0)"

unload() {
    echo Unloading NVIDIA drivers...
    sudo modprobe -r nvidia-uvm
    sudo modprobe -r nvidia-drm
    sudo modprobe -r nvidia-modeset
    sudo modprobe -r nvidia
    echo Disabling card...
    echo 'auto' | sudo tee "$POWER_CONTROL_FILE" > /dev/null;
}

load() {
    echo Enabling card...
    echo 'on' | sudo tee "$POWER_CONTROL_FILE"> /dev/null;
    echo Loading NVIDIA drivers...
    sudo modprobe nvidia
    sudo modprobe nvidia-modeset
    sudo modprobe nvidia-drm
    sudo modprobe nvidia-uvm
}

is_loaded() {
    lsmod | grep -i nvidia > /dev/null || grep -i on < "$POWER_CONTROL_FILE" > /dev/null 2>&1
}

toggle() {
    if is_loaded; then
        unload
    else
        load
    fi
}

print_status() {
    if is_loaded; then
        echo -e "${GREEN}[ON]$COLOR_RESET NVIDIA switched on and loaded"
    else
        echo -e "${RED}[OFF]$COLOR_RESET NVIDIA switched off and unloaded"
    fi
}

run_startx() {
    load
    print_status
    if is_loaded; then
        startx -- :42
    fi
    unload
}


main() {
    case "$1" in
        on )
            load
            ;;
        off )
            unload
            ;;
        toggle )
            toggle
            ;;
        startx )
            run_startx
            ;;
        is_on )
            is_loaded
            exit $?
            ;;
        pci )
            echo "$POWER_CONTROL_FILE"
            exit 0
            ;;
        -h|--help )
            echo Print or toggle status of dedicated NVIDIA card.
            echo "Usage: nvswitch.sh [-h|--help] [on|off|toggle|startx|is_on]"
            echo If no command specified, print the current status.
            exit
            ;;
        * )
            ;;
    esac

    print_status
}

main "$@"
