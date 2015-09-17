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
    fname="${1##*/}"
    fname="$2/${fname%.*}"
    
    $DEBUG && (echo "Convert \"$1\" to \"$fname.wav\"" && \
    echo "Strip metadata and save file to \"$fname-stripped.wav\"" && \
    echo "Rename \"$fname-stripped.wav\" to \"$fname.wav\"")

    $DEBUG || (ffmpeg -i "$1" -map_metadata -1 -ac 1 -ar 11025 "$fname.wav" && \
    shntool strip "$fname.wav" && \
    mv "$fname-stripped.wav" "$fname.wav")
}



# Default output directory is the working directory
dest=.

if [ $# -eq 0 ]; then
    echo "Converts a file to the half-life 1 sound format."
    echo "Usage:"
    echo "convert-to-hlsound.sh <files...> [directory]"
    exit
else
    if [ -d "${!#}" ]; then # is the last argument a directory?
        dest="${!#}"
        len=$(($#-1))
    else
        len=$#
    fi
    files=("${@:1:$len}")
fi

# Remove unnecessary slashes and ensure 1 trailing slash
# dest="$(removeslashes "$1/")"

$DEBUG && echo "files: ${files[@]}"
$DEBUG && echo "dest: $dest"

$DEBUG && echo "Create $dest"
$DEBUG || mkdir -p "$dest"

for i in "${files[@]}"; do
    convertfile "$i" "$dest"
done

