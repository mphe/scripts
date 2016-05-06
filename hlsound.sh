#!/bin/bash

#######################################################
# Requires ffmpeg, shntool, and optionally youtube-dl #
#######################################################

printhelp() {
    echo "(Downloads and) Converts a file to the half-life 1 sound format (suitable for micspam)."
    echo "If youtube-dl is installed it will be used to extract the video/audio URL from a given link."

    echo -e "\nUsage:\n\t${0##*/} <[options] file/url>..."
    echo -e "\nOptions:"
    echo -e "\tfile/url\tA file or URL to convert. If an URL is given and youtube-dl is available, it will be used to extract the stream URL. If not or if --noytdl is specified, the URL will be downloaded directly."
    echo -e "\t-d directory\tThe output directory for all files. If it doesn't exist, it will be created. It has no effect if -o is specified."
    echo -e "\t-h, --help\tShow help"
    echo -e "\t--debug\tDon't do anything, just print what would have been done."
    echo -e "\t--noytdl\tDon't use youtube-dl to extract the video/audio URL in the given URL."
    echo -e "\t-o name\tOutput name for the given file/url."
    echo -e "\t-ss time\tStart position in seconds or in the format 'H:M:S.MS'."
    echo -e "\t-t duration\tDuration in seconds or in the format 'H:M:S.MS'."
    echo -e "\t-to time\tEnd position in seconds or in the format 'H:M:S.MS'."
    echo -e "\nNote: -ss, -t and -to are passed directly to ffmpeg. See also 'man ffmpeg' for further information on these options."
}

isurl() {
    local regex='(https?|ftp)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    [[ "$1" =~ $regex ]]
}

main() {
    if [ $# -eq 0 ]; then
        printhelp
        exit
    fi

    command -v youtube-dl >/dev/null 2>&1 && HAS_YTDL=true || HAS_YTDL=false
    local NOYTDL=false
    local INFLAGS=
    local OUTFLAGS=
    local OUT=
    local OUTDIR=.
    local DEBUG=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help )
                printhelp
                exit
                ;;
            --debug )
                DEBUG=true
                ;;
            -o )
                OUT="$2"
                shift
                ;;
            -d )
                OUTDIR="$2"
                mkdir -p "$OUTDIR"
                shift
                ;;
            -ss )
                INFLAGS="-ss $2"
                shift
                ;;
            -t )
                OUTFLAGS="-t $2"
                shift
                ;;
            -to )
                OUTFLAGS="-to $2"
                shift
                ;;
            --noytdl )
                NOYTDL=true
                ;;
            * )
                local FILE="$1"

                if isurl "$FILE" && $HAS_YTDL && ! $NOYTDL; then
                    IFS=$'\n' 
                    if local data=($(youtube-dl -xge "$FILE")); then
                        if [[ -z "$OUT" ]] && [[ ${#data[@]} -gt 1 ]]; then
                            OUT="$OUTDIR/${data[0]}.wav"
                        fi
                        FILE="${data[-1]}"
                    fi
                    unset IFS
                fi

                if [[ -z "$OUT" ]]; then
                    OUT="$(basename "$FILE")"
                    OUT="$OUTDIR/${OUT%.*}.wav"
                fi

                convertfile "$FILE" "$OUT" "$INFLAGS" "$OUTFLAGS"

                # reset
                NOYTDL=false
                INFLAGS=
                OUTFLAGS=
                OUT=
                ;;
        esac
        shift
    done
}

# arg1: input filename
# arg2: output filename
# arg3: input flags
# arg4: output flags
convertfile() {
    local OUTFILE="$(mktemp "/tmp/$(basename "$2").XXXXXXXXX.wav")"
    if $DEBUG; then
        echo "ffmpeg -y $3 -i \"$1\" $4 -copyts -map_metadata -1 -ac 1 -ar 11025 \"$OUTFILE\""
        echo "shntool strip \"$OUTFILE\""
        echo "mv \"${OUTFILE%.wav}-stripped.wav\" \"$2\""
        echo "rm \"$OUTFILE\""
    else
        ffmpeg -y $3 -i "$1" $4 -copyts -map_metadata -1 -ac 1 -ar 11025 "$OUTFILE"
        shntool strip "$OUTFILE"
        mv "${OUTFILE%.wav}-stripped.wav" "$2"
    fi
    rm "$OUTFILE"
}

main "$@"
