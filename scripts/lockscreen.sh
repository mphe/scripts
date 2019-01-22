#!/bin/bash
# Adapted from https://github.com/michael-kaiser/dotfiles/blob/master/i3/lockscreen.sh
# Requirements: http://www.fmwconcepts.com/imagemagick/videoglitch/index.php
# 	            Imagemagick

# Wait a bit so popup menus can close
sleep 0.1

scrot /tmp/screen.png
# convert /tmp/screen.png -scale 10% -scale 1000% /tmp/screen.png
# videoglitch -n 20 -j 10 -c red-cyan /tmp/screen.png /tmp/screen.png
videoglitch -n 20 /tmp/screen.png /tmp/screen.png

if [[ -f $HOME/.config/lock.png ]]
then
    # placement x/y
    PX=0
    PY=0
    # lockscreen image info
    R=$(file ~/.config/lock.png | grep -o '[0-9]* x [0-9]*')
    RX=$(echo $R | cut -d' ' -f 1)
    RY=$(echo $R | cut -d' ' -f 3)
 
    SR=$(xrandr --query | grep ' connected' | sed 's/primary //' | cut -f3 -d' ')
    for RES in $SR
    do
        # monitor position/offset
        SRX=$(echo $RES | cut -d'x' -f 1)                   # x pos
        SRY=$(echo $RES | cut -d'x' -f 2 | cut -d'+' -f 1)  # y pos
        SROX=$(echo $RES | cut -d'x' -f 2 | cut -d'+' -f 2) # x offset
        SROY=$(echo $RES | cut -d'x' -f 2 | cut -d'+' -f 3) # y offset
        PX=$(($SROX + $SRX/2 - $RX/2))
        PY=$(($SROY + $SRY/2 - $RY/2))
 
        convert /tmp/screen.png $HOME/.config/lock.png -geometry +$PX+$PY -composite -matte  /tmp/screen.png
        echo "done"
    done
fi

i3lock -e -i /tmp/screen.png
