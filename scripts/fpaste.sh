#!/bin/bash

FILE_LIST="/dev/shm/file_move_script_308b12b3-0302-401b-a68f-d5149aeaf976"

printhelp() {
    echo "Move or copy files like in a file browser"
    echo -e "Usage:\n\t${0##*/} [-h|--help] operation [files...] [target directory]"
    echo -e "\nOperations:"
    echo -e "\thelp\tShow help."
    echo -e "\tmark\tMark files."
    echo -e "\tadd\tMark files but without clearing previously marked files."
    echo -e "\tmove\tMove marked files to given target directory or current directory, otherwise."
    echo -e "\tcopy\tCopy marked files to given target directory or current directory, otherwise."
    echo -e "\tlink\tSymlink marked files to given target directory or current directory, otherwise."
    echo -e "\tclear\tUnmark all files"
    echo -e "\tlist\tShow marked files and the operation to do"
}

# Mark files but clear previous entries
# argN: files
mark() {
    clearlist
    mark_add "$@"
}

# Mark files without clearing previous entries
# argN: files
mark_add() {
    # Make sure they are newline separated
    for i in "$@"; do
        realpath "$i" >> "$FILE_LIST"
    done
}

# Returns successful if there are marked files, otherwise shows an error message and returns 1.
check_files_marked() {
    if ! [ -f "$FILE_LIST" ]; then
        echo "No files marked"
        return 1
    fi
}

list() {
    if check_files_marked; then
        cat "$FILE_LIST"
    fi
}

clearlist() {
    [ -f "$FILE_LIST" ] && rm "$FILE_LIST"
}

# arg1: command
# arg2: target dir (optional)
apply() {
    check_files_marked || return 1

    local target="${2:-.}"
    # shellcheck disable=SC2086
    xargs -d '\n' -I % $1 % "$target" < "$FILE_LIST"
}

main() {
    if [ $# -eq 0 ]; then
        printhelp
        exit
    fi

    local op="$1"
    shift

    case "$op" in
        copy )
            apply "cp -rv" "$@"
            ;;
        move )
            apply "mv -v" "$@"
            clearlist
            ;;
        link )
            apply "ln -sv" "$@"
            ;;
        list )
            list
            ;;
        mark )
            mark "$@"
            ;;
        add )
            mark_add "$@"
            ;;
        clear )
            clearlist
            ;;
        -h|--help|help )
            printhelp
            ;;
        * )
            echo "Unrecognized operation: $op"
            exit 1
            ;;
    esac
}

main "$@"
