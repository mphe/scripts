#!/usr/bin/env bash

PCISLOT="$(lspci | grep -i nvidia | cut -d ' ' -f 1)"
POWER_CONTROL_FILE="/sys/bus/pci/devices/0000:$PCISLOT/power/control"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
COLOR_RESET="$(tput sgr0)"
NVIDIA_VK_ICD=/usr/share/vulkan/icd.d/nvidia_icd.json
INTEL_VK_ICD=/usr/share/vulkan/icd.d/intel_icd.i686.json:/usr/share/vulkan/icd.d/intel_icd.x86_64.json
NVIDIA_EGL_VENDOR=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
INTEL_EGL_VENDOR=/usr/share/glvnd/egl_vendor.d/50_mesa.json


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

print_env_on() {
    # https://wiki.archlinux.org/title/Bumblebee#Discrete_card_is_silently_activated_when_egl_is_requested_by_some_application
    # https://wiki.archlinux.org/title/Vulkan?useskinversion=1#Selecting_Vulkan_driver
    # https://wiki.archlinux.org/title/Hardware_video_acceleration?useskinversion=1#Configuration
    echo export VK_ICD_FILENAMES="'$NVIDIA_VK_ICD'"
    echo export __EGL_VENDOR_LIBRARY_FILENAMES="'$NVIDIA_EGL_VENDOR'"
    echo export LIBVA_DRIVER_NAME=vdpau
    echo export VDPAU_DRIVER=nvidia
}

print_env_off() {
    # https://wiki.archlinux.org/title/Bumblebee#Discrete_card_is_silently_activated_when_egl_is_requested_by_some_application
    # https://wiki.archlinux.org/title/Vulkan?useskinversion=1#Selecting_Vulkan_driver
    # https://wiki.archlinux.org/title/Hardware_video_acceleration?useskinversion=1#Configuration
    echo export VK_ICD_FILENAMES="'$INTEL_VK_ICD'"
    echo export __EGL_VENDOR_LIBRARY_FILENAMES="'$INTEL_EGL_VENDOR'"
    echo export LIBVA_DRIVER_NAME=iHD
    echo export VDPAU_DRIVER=va_gl
}

run_startx() {
    load
    print_status
    if is_loaded; then
        eval "$(print_env_on)"
        startx -- :42
        eval "$(print_env_off)"
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
            exit
            ;;
        env_off )
            print_env_off
            exit
            ;;
        env_on )
            print_env_on
            exit
            ;;
        -h|--help )
            echo Print or toggle status of dedicated NVIDIA card.
            echo "Usage: nvswitch.sh [-h|--help] [on|off|toggle|startx|is_on|pci|env_on|env_off]"
            echo If no command specified, print the current status.
            exit
            ;;
        * )
            ;;
    esac

    print_status
}

main "$@"
