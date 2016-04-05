#!/bin/bash

#######################################################
# Requires ffmpeg, shntool, and optionally youtube-dl #
#######################################################

# Set DEBUG to true to disable actual conversion and print debug information instead
DEBUG=${DEBUG:-false}


removeslashes() {
    echo "$1" | sed s#//*#/#g
}

convertfile() {
    local file="$1"
    local dest="$2"
    local out="$3"

    if [ -n $youtubedl ] && [[ "$file" =~ $regex ]]; then
        if [ -z "$out" ]; then
            if ! out="$($youtubedl -e "$file")"; then
                out=''
            fi
        fi

        if ! file=$($youtubedl -xg "$file"); then
            file="$1"
        fi
    fi

    # Strip path and extension from filename and add destination path
    local fname
    if [ -z "$out" ]; then
        fname="${file##*/}"
    else
        fname="$out"
    fi
    fname="$dest/${fname%.*}"
    
    if $DEBUG; then
        echo "Convert '$file' to '$fname.wav'"
        echo "Strip metadata and save file to '$fname-stripped.wav'"
        echo "Rename '$fname-stripped.wav' to '$fname.wav'"
    else
        ffmpeg -i "$file" -map_metadata -1 -ac 1 -ar 11025 "$fname.wav"
        shntool strip "$fname.wav"
        mv "$fname-stripped.wav" "$fname.wav"
    fi
}


if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Converts a file to the half-life 1 sound format."
    echo -e "Usage:\n\t${0##*/} <files/urls [-o name]>... [directory]"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\tShow help"
    echo -e "\t-o\tOutput name for the given file/url"
    echo -e "\t--noytdl\tDon't use 'youtube-dl -xg <url>' on URLs"
    exit
fi

# Default output directory is the working directory
dest=.
regex='(https?|ftp)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
youtubedl=$(command -v youtube-dl >/dev/null 2>&1 && echo 'youtube-dl')

if [ -d "${!#}" ]; then # is the last argument a directory?
    dest="${!#}"
    $DEBUG && echo "dest: $dest"
    $DEBUG && echo "Creating $dest"
    $DEBUG || mkdir -p "$dest"
fi

while [ $# -gt 1 ]; do
    if [ "$1" == '--noytdl' ];then
        youtubedl=''
        shift
    fi

    file="$1"
    shift
    if [ "$1" == '-o' ]; then
        shift
        out="$1"
        shift
    else
        out=''
    fi

    convertfile "$file" "$dest" "$out"
done

if [ -n "$1" ] && ! [ -d "$1" ]; then # was the last argument a file?
    convertfile "$1" "$dest"
fi
