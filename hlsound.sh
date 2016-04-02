#!/bin/bash

###############################
# Requires ffmpeg and shntool #
###############################

# Set DEBUG to true to disable actual conversion and print debug information instead
DEBUG=${DEBUG:-false}


removeslashes() {
    echo "$1" | sed s#//*#/#g
}

convertfile() {
    # Strip path and extension from filename and add destination path
    local fname
    if [ -z "$3" ]; then
        fname="${1##*/}"
    else
        fname="$3"
    fi
    fname="$2/${fname%.*}"
    
    if $DEBUG; then
        echo "Convert '$1' to '$fname.wav'"
        echo "Strip metadata and save file to '$fname-stripped.wav'"
        echo "Rename '$fname-stripped.wav' to '$fname.wav'"
    else
        ffmpeg -i "$1" -map_metadata -1 -ac 1 -ar 11025 "$fname.wav"
        shntool strip "$fname.wav"
        mv "$fname-stripped.wav" "$fname.wav"
    fi
}





if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Converts a file to the half-life 1 sound format."
    echo -e "Usage:\n\t${0##*/} <files/urls [-o name]>... [-d directory]"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\tShow help"
    echo -e "\t-d\tUse a specific output directory"
    echo -e "\t-o\tOutput name for the given file/url"
    exit
fi

# Default output directory is the working directory
dest=.

if [ -d "${!#}" ]; then # is the last argument a directory?
    dest="${!#}"
    $DEBUG && echo "dest: $dest"
    $DEBUG && echo "Creating $dest"
    $DEBUG || mkdir -p "$dest"
fi

while [ $# -gt 1 ]; do
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
