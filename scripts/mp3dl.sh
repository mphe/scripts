#!/bin/sh
FORMAT="%(title)s.%(ext)s"

if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo Download the audio track of a video and convert it to mp3.
    echo -e "Usage:\n\t$0 [-h | --help] <URL> [URL...]"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\tShow help"
    exit
else
    youtube-dl -x --audio-format mp3 -o "$FORMAT" "$@"
fi
