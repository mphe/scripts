#!/bin/bash

main() {
    if [[ $# == 0 ]]; then
        printhelp
        exit
    fi

    local NUMLOOPS=1
    local CONCAT=''
    local VERBOSE=false

    while [[ $# > 1 ]]; do
        case $1 in
            -h|--help )
                printhelp
                exit
                ;;
            -v|--verbose )
                VERBOSE=true
                ;;
            -l|--loop )
                NUMLOOPS=$2
                shift
                ;;
            - )
                echo "Unknown option: $1"
                ;;
            * )
                if $VERBOSE; then
                    echo "Loop file '$1' $NUMLOOPS times"
                fi
                for i in $(seq $NUMLOOPS); do
                    CONCAT="$CONCAT\nfile '$(readlink -f "$1")'"
                done
                NUMLOOPS=1
                ;;
        esac
        shift
    done

    if [[ -z "$CONCAT" ]] || [[ $# == 0 ]]; then
        echo "Error: Missing input/output filename(s)."
        exit 1
    fi

    if $VERBOSE; then
        echo -e "File list:\n$CONCAT\n"
        echo "Looping output $NUMLOOPS times"
    fi

    # Applying remaining options to the output
    local NEWCONCAT=''
    for i in {1..$NUMLOOPS}; do
        NEWCONCAT="$NEWCONCAT$CONCAT"
    done

    if $VERBOSE; then
        echo -e "Final file list:\n$NEWCONCAT\n"
        echo "Output file: $1"
    fi

    ffmpeg -f concat -safe 0 -i <(echo -e "$NEWCONCAT") -c copy "$1"
}

printhelp() {
    local NAME="${0##*/}"
    echo "Concatenate/Loop video/audio files using ffmpeg."
    echo -e "Usage:\n\t$NAME <[options] file>... <[options] output file>"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\tShow help"
    echo -e "\t-v, --verbose\tShow additional debug information"
    echo -e "\t-l, --loop <n>\tLoop the given file n times"
    echo -e "\nExample::"
    echo -e "\t$NAME -l 5 file1.mp3 file2.mp3 -l 2 file3.mp3 out.mp3"
    echo -e "This loops file1.mp3 5 times and concatenates it with file2.mp3 and file3.mp3, which is looped 2 times."
    echo -e "\n\t$NAME file1.mp3 --loop 2 file2.mp3 -l 5 out.mp3"
    echo -e "Loop file2.mp3 twice and concatenate with file1.mp3. Then loop this all together 5 times and write it to out.mp3."
}

main "$@"
