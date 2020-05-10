#!/bin/bash

# Path to gmad extractor binary
GMAD=gmad_linux
GMAFILE=

printhelp() {
    local SELF="${0##*/}"
    echo -e "Download files from steam workshop directly."
    echo -e "Requires \"Gmad Extractor\" to extract .gma files"

    echo -e "Usage:\n\t$SELF [options] <URL>"

    echo -e "Options:"
    echo -e "\t-h, --help\tShow help."
    echo -e "\t-v, --verbose\tShow debug output."
    echo -e "\t-b gmad_binary\t\tChange the gmad extractor path. By default it searches for gmad_linux in PATH."
}

main() {
    local VERBOSE=false

    while [[ $# -gt 1 ]]; do
        case "$1" in
            -h|--help )
                printhelp
                exit
                ;;
            -v|--verbose )
                VERBOSE=true
                ;;
            -b )
                GMAD="$2"
                shift
                ;;
            * )
                echo "Unknown option: $1"
                ;;
        esac
        shift
    done


    trap cleanup EXIT

    # Extract id
    # Example url: http://steamcommunity.com/sharedfiles/filedetails/?id=238575181
    local WSID="$(echo "$1" | grep -Eo "id=[0-9]+")"
    WSID="${WSID:3}"

    # extract download url
    local URL="$(curl -s "http://steamworkshop.download/download/view/$WSID" | grep "steamusercontent" | sed -r "s/.*href='(.+)'.*/\1/" | sed -r "s/'.*//")"

    $VERBOSE && echo "ID: $WSID"
    $VERBOSE && echo "Downloading: $URL"

    # download
    GMAFILE="$(mktemp /tmp/steam-workshop-XXXXXXXXX.gma)"
    # wget -O $GMAFILE "$URL"
    curl -o $GMAFILE "$URL"
    echo "Size: $(du -h $GMAFILE)"

    # extract
    "$GMAD" extract -file "$GMAFILE" -out "./"
}

cleanup() {
    [[ -n "$GMAFILE" ]] && rm "$GMAFILE"
}

main "$@"
