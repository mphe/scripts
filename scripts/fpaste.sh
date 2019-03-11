#!/bin/bash

FNAME="/dev/shm/file_move_script_308b12b3-0302-401b-a68f-d5149aeaf976"

printhelp() {
    echo "Move or copy files like in a file browser"
    echo -e "Usage:\n\t${0##*/} [-h|--help] operation [files...]"
    echo -e "\nOperations:"
    echo -e "\thelp\tShow help"
    echo -e "\tcut\tMark files to be moved"
    echo -e "\tcopy\tMark files to be copied"
    echo -e "\tpaste\tPaste marked files"
    echo -e "\tclear\tUnmark all files"
    echo -e "\tlist\tShow marked files and the operation to do"
}

# arg1: operation
# argN: files
mark() {
    echo "$1" > "$FNAME"
    shift

    for i in "$@"; do
        echo "$(realpath "$i")" >> "$FNAME"
    done
}

list() {
    if ! [ -f "$FNAME" ]; then
        echo "No files marked"
        exit 1
    else
        cat "$FNAME"
    fi
}

clearlist() {
    if [ -f "$FNAME" ]; then
        rm "$FNAME"
    fi
}

paste() {
    if ! [ -f "$FNAME" ]; then
        echo "No files marked"
        exit 1
    fi

    local op="$(head -n 1 "$FNAME")"
    local cmd=

    case "$op" in
        copy )
            cmd=cp
            ;;
        cut )
            cmd=mv
            ;;
        * )
            echo "Unrecognized operation: $cmd"
            exit 1
            ;;
    esac

    while read -r line; do
        $cmd "$line" .
    done <<< "$(tail -n +2 "$FNAME")"

    if [ "$op" == "cut" ]; then
        rm "$FNAME"
    fi
}


if [ $# -eq 0 ]; then
    printhelp
    exit
fi

OP="$1"
shift

case "$OP" in
    copy )
        mark copy "$@"
        ;;
    cut )
        mark cut "$@"
        ;;
    list )
        list
        ;;
    paste )
        paste
        ;;
    clear )
        clearlist
        ;;
    -h|--help|help )
        printhelp
        ;;
    * )
        echo "Unrecognized operation: $OP"
        exit 1
        ;;
esac

