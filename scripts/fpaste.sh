#!/bin/bash

# TODO: Consider changing syntax to
# $ fpaste mark files...
# $ fpaste cut/copy/link
# instead of specifying the operation beforehand

FNAME="/dev/shm/file_move_script_308b12b3-0302-401b-a68f-d5149aeaf976"

printhelp() {
    echo "Move or copy files like in a file browser"
    echo -e "Usage:\n\t${0##*/} [-h|--help] operation [files...]"
    echo -e "\nOperations:"
    echo -e "\thelp\tShow help"
    echo -e "\tcut\tMark files to be moved"
    echo -e "\tcopy\tMark files to be copied"
    echo -e "\tlink\tMark files to be symlinked"
    echo -e "\tpaste\tPaste marked files"
    echo -e "\tclear\tUnmark all files"
    echo -e "\tlist\tShow marked files and the operation to do"
}

# arg1: operation
# argN: files
mark() {
    # Write operation to use
    echo "$1" > "$FNAME"
    shift

    for i in "$@"; do
        realpath "$i" >> "$FNAME"
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
    [ -f "$FNAME" ] && rm "$FNAME"
}

paste() {
    if ! [ -f "$FNAME" ]; then
        echo "No files marked"
        exit 1
    fi

    # shellcheck disable=SC2155
    local op="$(head -n 1 "$FNAME")"
    local cmd=

    case "$op" in
        copy )
            cmd="cp -r"
            ;;
        cut )
            cmd="mv"
            ;;
        link )
            cmd="ln -s"
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
    copy|cut|link )
        mark "$OP" "$@"
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

exit 0
