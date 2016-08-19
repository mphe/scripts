#!/bin/bash

printhelp() {
    echo -e "Download all episodes of a season from burning series using youtube-dl."
    echo -e "Usage:\n\t${0##*/} [-h | --help] <URL> <hoster> [options]"
    echo -e "Options:"
    echo -e "\t-h, --help\tShow help"
    echo -e "\t-p\t\tDownload multiple files in parallel"
    echo -e "\t-m\t\tMaximum amount of parallel downloads. Default is 4."
    echo -e "\t-g\t\tDon't download anything, just print the download links to stdout."
    echo -e "\t-l\t\tSame as -g but print the video hoster links, not direct links. (Faster than -g)"
    echo -e "\t-s\t\tSkip a file if an error occurs."
    echo -e "Example:"
    echo -e "\t${0##*/} https://bs.to/serie/Akame-ga-Kill/1 vivo -p"
    echo -e "\tmpv \$(${0##*/} https://bs.to/serie/Akame-ga-Kill/1 vivo -l)"
    echo -e "\t\tNote: this might take a while until all links are extracted."
    echo -e "\tmplayer \$(${0##*/} https://bs.to/serie/Akame-ga-Kill/1 vivo -g)"
    echo -e "\t\tNote: takes even longer than -l."
}

# arg1: link to the episode's page
get_url() {
    echo "$(curl -s "$1" | grep -i "alt='video'" | sed -r "s/.*href='(.+)'.*/\1/" | sed "s/'.*//")"
}

# arg1: link to the episode's page
get_name() {
    local NAME=${line%/*}
    echo "${NAME##*/}"
}

# Same as download() but for parallel downloading
# arg1: stream link
# arg2: name
# arg3: skip on error (true/false)
download_p() {
    download "$@"
    inc_downloads -1
}

# arg1: stream link
# arg2: name
# arg3: skip on error (true/false)
download() {
    local BLUE="$(tput setaf 4)"
    local RESET="$(tput sgr0)"
    echo -e "\n${BLUE}[Downloading]$RESET $2 ( $1 )"
    until youtube-dl -o "$2.%(ext)s" -R 50 "$1" || $3; do
        :
    done
}

# arg1: amount (can be negative)
inc_downloads() {
    echo $(($(<"$NUMDOWNLOADS") $1)) > "$NUMDOWNLOADS"
}

num_downloads() {
    echo $(<"$NUMDOWNLOADS")
}

cleanup() {
    until [[ $(num_downloads) -eq 0 ]]; do
        sleep 1
    done
    rm "$NUMDOWNLOADS"
}

main() {
    if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        printhelp
        exit
    fi

    if [[ ${1:0:1} == '-' ]] || [[ ${2:0:1} == '-' ]]; then
        echo "Warning: first or second parameter starts with '-'. Did you forget the hoster?"
        until [[ $REPLY =~ ^[YyNn]$ ]]; do
            read -p "Abort?  [y/N] " -n 1 -r
            echo
        done
        [[ $REPLY =~ ^[Yy]$ ]] && exit
    fi

    local SRC="$(curl -s "$1" | grep -i "$2" | grep -i href | sed -r "s/.*href=\"(.+)\".*/\1/")"
    shift 2

    local PARALLEL=false
    local EXTRACTONLY=0
    local MAXDOWNLOADS=4
    local SKIP=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help )
                ;;
            -p )
                PARALLEL=true
                ;;
            -g )
                EXTRACTONLY=1
                ;;
            -l )
                EXTRACTONLY=2
                ;;
            -s )
                SKIP=true
                ;;
            -m )
                MAXDOWNLOADS=$2
                shift
                ;;
            * )
                echo "Unknown option: $1"
                ;;
        esac
        shift
    done

    if $PARALLEL; then
        # Shared memory to store the current amount of parallel downloads
        NUMDOWNLOADS=$(mktemp /dev/shm/bs-downloads-XXXXXXXXX)
        trap cleanup EXIT
    fi

    echo "$SRC" | while read -r line; do
        local PAGE="https://bs.to/$line"
        local NAME="$(get_name "$PAGE")"
        local URL="$(get_url "$PAGE")"

        if [[ $EXTRACTONLY -eq 0 ]]; then
            if $PARALLEL; then
                until [[ $(num_downloads) -lt $MAXDOWNLOADS ]]; do
                    sleep 1
                done
                inc_downloads +1
                download_p "$URL" "$NAME" $SKIP &
            else
                download "$URL" "$NAME" $SKIP
            fi
        elif [[ $EXTRACTONLY -eq 1 ]]; then
            youtube-dl -g "$URL"
        elif [[ $EXTRACTONLY -eq 2 ]]; then
            echo "$URL"
        fi
    done
}

main "$@"
