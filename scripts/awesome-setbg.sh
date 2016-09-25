#!/bin/bash

# Runs the lua command to set the wallpaper.
# arg1: path to image
# arg2: type (centered, fit, maximized)
# arg3: screen (leave blank for all screens)
set_wallpaper()
{
    if [[ -z $3 ]]; then
        echo "gears = require('gears')
              for s = 1, screen.count() do
                  gears.wallpaper.${2:-centered}('$1', s)
              end" | awesome-client
    else
        echo "gears = require('gears')
              gears.wallpaper.${2:-centered}('$1', $3)" | awesome-client
    fi
}

printhelp() {
    echo "Set the background in awesome wm."
    echo -e "Usage:\n\t${0##*/} [options] <filename> [options]"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\tShow help"
    echo -e "\t--apply\tMake the background permanent."
    echo -e "\t--reset\tReset the background to the last applied one."
    echo -e "\t--fit\tFit the background."
    echo -e "\t--maximize\tMaximize the background."
    echo -e "\t--center\tCenter the background."
    echo -e "\t-s, --screen <n>\tMake changes only to the nth screen."
}

main() {
    local FNAME=
    local SCREEN=
    local APPLY=false
    local TYPE=centered

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help )
                printhelp
                exit
                ;;
            --apply )
                APPLY=true
                ;;
            --maximize )
                TYPE=maximized
                ;;
            --center )
                TYPE=centered
                ;;
            --fit )
                TYPE=fit
                ;;
            --reset )
                FNAME=~/.cache/awesome/wallpaper.png
                ;;
            -s|--screen )
                SCREEN=$2
                shift
                ;;
            * )
                FNAME="$(realpath "$1")"
                ;;
        esac
        shift
    done

    [[ -n "$FNAME" ]] && set_wallpaper "$FNAME" $TYPE $SCREEN || exit 1

    if $APPLY; then
        cd ~/.cache/awesome
        mv wallpaper.png wallpaper.png.bak
        cp "$FNAME" wallpaper.png
    fi
}

main "$@"
