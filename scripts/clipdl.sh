#!/bin/bash

INTERVAL=1
LASTCLIP=""
URLS=""
MAXJOBS=6
DOWNLOADER=youtube-dl  # Also supports wget

question() {
    local ANS
    until [[ $ANS =~ ^[YyNn]$ ]]; do
        read -p "$1?  [y/N] " -n 1 -r ANS
        echo
    done
    [[ $ANS =~ ^[Yy]$ ]] && return 0 || return 1
}

# arg1: url
# arg2: use youtube-dl to query title (bool)
add_url() {
    # is url?
    if ! [[ "$1" =~ ^[[:space:]]*https?://.* ]]; then
        return 1
    fi

    # check duplicate
    if echo -e "$URLS" | grep -E "^$1\$" > /dev/null; then
        echo "Duplicate URL -> Skipped ($1)"
        return
    fi

    # prevent empty line at start
    if [[ -z "$URLS" ]]; then
        URLS="$1"
    else
        URLS="$URLS\n$1"
    fi
    echo -e "URL added: $1"

    if ${2:-true} && [ "$DOWNLOADER" == "youtube-dl" ]; then
        echo -e "\t$(youtube-dl -e "$1")" &
    fi
}

check_clipboard() {
    local clip="$(xclip -o -selection c)"

    # Don't include current content at start
    [[ -z "$LASTCLIP" ]] && LASTCLIP="$clip"

    [[ "$clip" == "$LASTCLIP" ]] && return 1

    LASTCLIP="$clip"

    add_string "$clip"
}

# Splits the string in lines and tests each line individually for a URL
# arg1: string
# arg2: use youtube-dl to query title (bool)
add_string() {
    while IFS= read -r line; do
        add_url "$line" "$2"
    done <<< "$1"
}

# Dump URL list if something happens
dump() {
    [ -z "$URLS" ] && return
    local fname="$(mktemp "$PWD/urls.XXXXXXXX.txt")"
    echo -e "\nError: Exited unsuccessfully"
    echo -e "Dumping URLs to $fname"
    echo -e "$URLS" > "$fname"
}

main() {
    if [ "$1" == "wget" ] || [ "$1" == "youtube-dl" ]; then
        DOWNLOADER="$1"
        shift
    fi

    echo "Using $DOWNLOADER as downloader"

    if [ -n "$1" ]; then
        echo "Loading URLs from file $1"
        if [[ -f "$1" ]]; then
            # Don't query title because it might spawn too many
            # processes at once
            add_string "$(<"$1")" false
        else
            echo "Error: File does not exist"
        fi

        # Wait for youtube-dl -e subprocesses
        # for job in $(jobs -p); do
        #     wait "$job"
        # done

        shift
        echo
    fi

    echo "Waiting for URLs being copied to clipboard..."
    echo -e "Press Enter to start download.\n"

    # Dump URLs if something goes wrong
    trap dump EXIT

    while true; do
        check_clipboard
        read -r -t $INTERVAL && break
        # sleep "$INTERVAL"
    done

    if question "Edit URLs"; then
        local URLLIST=$(mktemp /dev/shm/clipdl.XXXXXXXX)
        echo -e "$URLS" > "$URLLIST"
        ${EDITOR:-vim} "$URLLIST"
        URLS="$(grep -vE '^\s*$' "$URLLIST")"
        rm "$URLLIST"
    fi

    echo "Downloading..."
    echo -e "$URLS" | parallel -u --jobs $MAXJOBS --max-args=1 "$@" "$DOWNLOADER"
    local err=$?
    [ "$err" -ne 0 ] && exit $err

    trap - EXIT  # Don't run trap when exiting normally
}

main "$@"
