#!/bin/bash

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo -e "Search /etc for .pacnew files and invoke vimdiff on them."
    echo -e "After each file ask for removal.\n"
    echo -e "Options:"
    echo -e "\t-h, --help:\tShow help."
    echo -e "\t-l, --list:\tOnly list .pacnew files without invoking vimdiff."
elif [[ "$1" == "-l" ]] || [[ "$1" == "--list" ]]; then
    find /etc -name '*.pacnew'
else
    dowork () {
        if which nvim > /dev/null 2>&1; then
            nvim -d "$(echo $1 | sed s/.pacnew$//)" "$1"
        else
            vimdiff "$(echo $1 | sed s/.pacnew$//)" "$1"
        fi

        read -p "Remove $1 ? [y/n] " -n 1 -r
        echo
        [[ $REPLY =~ ^[YyJj]$ ]] && sudo rm "$1"
    }
    export -f dowork
    find /etc -name '*.pacnew' -execdir bash -c 'dowork {}' \;
fi
