#!/usr/bin/env bash
# Requires notify-send.py (pip)

save_file() {
    if [ -z "$FILENAME" ]; then
        FILENAME="$(zenity --file-selection --save --confirm-overwrite --filename="screenshot$(date +%Y%m%d%H%M%S).png")" || return 1
    fi

    cp "$TMPFILE" "$FILENAME"
    echo "Saved"
}

clipboard() {
    xclip -selection clipboard -t image/png "$TMPFILE"
    echo "Copied"
}


if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Takes a screenshot using maim and displays a notification with possible actions."
    echo -e "Usage:\n\t${0##*/} [filename] [maim options]"
    exit
fi

FILENAME=""
if [[ "$1" != -* ]]; then
    FILENAME="$1"
    shift
fi


TMPFILE="$(mktemp /dev/shm/screenshot_sh.XXXXXX)"

maim "$@" > "$TMPFILE" || exit 1

trap "rm -f '$TMPFILE'" 0               # EXIT
trap "rm -f '$TMPFILE'; exit 1" 2       # INT
trap "rm -f '$TMPFILE'; exit 1" 1 15    # HUP TERM

ANS="$(notify-send.py -i "$TMPFILE" -t 0 test --action save:Save "copy:Copy to clipboard" both:Both discard:Discard | head -n 1)"

case $ANS in
    save )
        save_file
        ;;
    copy )
        clipboard
        ;;
    both )
        clipboard
        save_file
        ;;
    discard )
        ;;
esac
