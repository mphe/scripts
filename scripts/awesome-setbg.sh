#!/bin/bash

# Runs the lua command to set the wallpaper.
# arg1: path to image
set_wallpaper()
{
    echo "gears = require('gears')
          for s = 1, screen.count() do
              gears.wallpaper.centered('$1', s)
          end" | awesome-client
}

printhelp() {
    echo "Set the background in awesome wm."
    echo -e "Usage:\n\t${0##*/} [options] <filename>"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\tShow help"
    echo -e "\t--apply\tMake the background permanent."
    echo -e "\t--reset\tReset the background to the last applied one."
}

main() {
    local FNAME=
    local APPLY=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help )
                printhelp
                exit
                ;;
            --apply )
                APPLY=true
                ;;
            --reset )
                FNAME=~/.cache/awesome/wallpaper.png
                break
                ;;
            * )
                FNAME="$(realpath "$1")"
                ;;
        esac
        shift
    done

    [[ -n "$FNAME" ]] && set_wallpaper "$FNAME" || exit 1

    if $APPLY; then
        cd ~/.cache/awesome
        mv wallpaper.png wallpaper.png.bak
        cp "$FNAME" wallpaper.png
    fi
}

main "$@"
