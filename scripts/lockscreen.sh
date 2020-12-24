#!/bin/bash
# Adapted from https://github.com/michael-kaiser/dotfiles/blob/master/i3/lockscreen.sh
# Requirements: http://www.fmwconcepts.com/imagemagick/videoglitch/index.php
# 	            Imagemagick, maim

cd "$(dirname "$(readlink -f "$0")")" || exit 1

IMAGE_PATH="$(mktemp /dev/shm/lockscreen.XXXXXX.png)"

cleanup() {
    [[ -f "$IMAGE_PATH" ]] && rm -fv "$IMAGE_PATH"
}

main() {
    # Wait a bit so popup menus can close
    sleep 0.5

    trap cleanup 0               # EXIT
    trap "cleanup; exit 1" 2     # INT
    trap "cleanup; exit 1" 1 15  # HUP TERM

    # scrot --overwrite "$IMAGE_PATH"
    maim "$IMAGE_PATH"

    # Start i3lock with the current screen image and restart later when the
    # actual image is ready
    i3lock --nofork -i "$IMAGE_PATH" &
    local i3lock_pid=$!

    # convert "$IMAGE_PATH" -scale 10% -scale 1000% "$IMAGE_PATH"
    # convert "$IMAGE_PATH" -scale 50% "$IMAGE_PATH"
    # videoglitch -n 20 -j 10 -c red-cyan "$IMAGE_PATH" "$IMAGE_PATH"
    ./videoglitch -n 20 "$IMAGE_PATH" "$IMAGE_PATH"
    # convert "$IMAGE_PATH" -scale 200% "$IMAGE_PATH"

    # Kill old i3lock instance or exit if it fails, because the screen was
    # probably already unlocked then.
    kill $i3lock_pid > /dev/null 2>&1 || exit 0

    i3lock -e -i "$IMAGE_PATH"
}

main "$@"



# This was in the original script, but is not needed here
# if [[ -f "$IMAGE_PATH" ]]; then
#     # placement x/y
#     PX=0
#     PY=0
#     # lockscreen image info
#     R=$(file "$IMAGE_PATH" | grep -o '[0-9]* x [0-9]*')
#     RX=$(echo $R | cut -d' ' -f 1)
#     RY=$(echo $R | cut -d' ' -f 3)
#  
#     SR=$(xrandr --query | grep ' connected' | sed 's/primary //' | cut -f3 -d' ')
#     for RES in $SR
#     do
#         # monitor position/offset
#         SRX=$(echo $RES | cut -d'x' -f 1)                   # x pos
#         SRY=$(echo $RES | cut -d'x' -f 2 | cut -d'+' -f 1)  # y pos
#         SROX=$(echo $RES | cut -d'x' -f 2 | cut -d'+' -f 2) # x offset
#         SROY=$(echo $RES | cut -d'x' -f 2 | cut -d'+' -f 3) # y offset
#         PX=$(($SROX + $SRX/2 - $RX / 2))
#         PY=$(($SROY + $SRY/2 - $RY / 2))
#  
#         convert "$IMAGE_PATH" "$IMAGE_PATH" -geometry +$PX+$PY -composite -matte  "$IMAGE_PATH"
#         echo "done"
#     done
# fi
