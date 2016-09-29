#!/bin/sh

printhelp() {
    echo "Opens the given paths in vim and uses the resulting filelist to batch rename these files."
    echo -e "Usage:\n\t${0##*/} [options] files"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\tShow help"
    echo -e "\t-d, --dry\tDon't rename anything, just print what would have been done."
    echo -e "\t--\tTerminate options list"
}

printedithelp() {
    echo "These are the destination file names."
    echo "You can edit them and the new names are applied automatically after the file is closed. Don't forget to save."
    echo "Empty lines are ignored."
    echo "To ignore a file, simply leave its path and name as it is."
    echo "These 5 help lines will be ignored!"
    echo
}

join() {
    local LEN=0
    while [ $# -gt 0 ]; do
        if [ -n "$1" ]; then
            echo -e "$1"
            (( LEN++ ))
        fi
        shift
    done
    return $LEN
}

cleanup() {
    rm $FILELIST
}

main() {
    trap cleanup EXIT

    local DRY=false
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help )
                printhelp
                exit
                ;;
            -d|--dry )
                DRY=true
                ;;
            -- )
                shift
                break
                ;;
            * )
                break
                ;;
        esac
        shift
    done

    if [ $# -eq 0 ]; then
        printhelp
        exit
    fi

    FILELIST=$(mktemp /dev/shm/batchrename.XXXXXXXX)
    printedithelp > $FILELIST
    join "$@" >> $FILELIST
    local LEN=$?

    while true; do
        vim $FILELIST

        # Strip help and remove empty lines
        local NEWFILELIST="$(cat $FILELIST | tail -n +$(printedithelp | wc -l) | grep -v '^$')"

        if [ -z "$NEWFILELIST" ] || [ $LEN -ne $(echo "$NEWFILELIST" | wc -l) ]; then
            echo "Error: Filelist length doesn't match input filelist length!"
            
            local REPLY=
            until [[ $REPLY =~ ^[AaEeCc]$ ]]; do
                read -p "Append orignal list and edit, only edit, or cancel?  [a/A/e/E/c/C] " -n 1 -r
                echo
            done

            if [[ $REPLY =~ ^[Cc]$ ]]; then
                exit 1
            elif [[ $REPLY =~ ^[Aa]$ ]]; then
                echo >> $FILELIST
                echo "This is the original filelist." >> $FILELIST
                echo "THESE 2 LINES AND THE FILELIST MUST BE REMOVED MANUALLY!" >> $FILELIST
                join "$@" >> $FILELIST
            fi
        else
            break
        fi
    done

    while [ $# -gt 0 ] && IFS= read -r line; do
        if [ "$1" != "$line" ]; then
            # TODO : Check for overwriting (mv -vi doesn't work because of stdin interference)
            $DRY && echo "$1 -> $line" || mv -v "$1" "$line"
        fi
        shift
    done <<< "$NEWFILELIST"
}

main "$@"
