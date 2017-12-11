#!/bin/bash

printhelp() {
    local SELF="${0##*/}"
    local EXURL="https://bs.to/serie/Shinsekai-Yori/1"
    echo -e "Download all or only certain episodes of a season from burning series using youtube-dl."
    echo -e "Requires cefget.py to be in \$PATH to show captcha dialogues."
    echo -e "Usage:\n\t$SELF [-h | --help] <URL> <hoster> [options]"
    echo -e "Options:"
    echo -e "\t-h, --help\tShow help."
    echo -e "\t-p\t\tDownload multiple files in parallel."
    echo -e "\t-m\t\tMaximum amount of parallel downloads. Default is 4."
    echo -e "\t-g\t\tDon't download anything, just print the download links to stdout."
    echo -e "\t-l\t\tSame as -g but print the video hoster links, not direct links. (Faster than -g)"
    echo -e "\t-r\t\tDon't skip the file if an error occurs. Use with caution because killing the process might be the only way to cancel the script."
    echo -e "\t-ss <start>\tDownload all episodes starting from <start> (including <start> itself). Has no effect if -e is supplied."
    echo -e "\t-e <list>\tDownload only the episodes specified in <list>. <list> is a comma separated list (without spaces) of episode numbers. Has precedence over -ss."
    echo -e "\t-v\t\tInvert episode selection (download everything except episodes specified with -e or -ss)."
    echo -e "\t-w\t\tUse the wayback machine for link extraction. Requires the input link to be a wayback machine link to the season."
    echo -e "\t-wh\t\tUse wayback machine hoster links. Can only be used in combination with -w."
    echo -e "\t-a\t\tPrompt for captcha when downloading a file rather than for all files at once in the beginning."
    echo -e "\t-s <seconds>\tSleep for a given amount of seconds before extracting another URL. Might reduce captcha complexity."
    echo -e "\nExamples:"
    echo -e "\t$SELF $EXURL vivo -p"
    echo -e "\n\t$SELF $EXURL vivo -p -m 2 -e 1 -v"
    echo -e "\n\t$SELF $EXURL vivo -p -m 2 -e 20,21,22,23"
    echo -e "\n\t$SELF $EXURL vivo -ss 12"
    echo -e "\n\tmpv \$($SELF $EXURL vivo -l)"
    echo -e "\t\tNOTE: this might take a while until all links are extracted."
    echo -e "\n\tmplayer \$($SELF $EXURL vivo -g)"
    echo -e "\t\tNOTE: takes even longer than -l."
}

# arg1: link to the episode's page
get_url() {
    echo "$(curl -s "$1" | grep -i "class=\"hoster-player\"" | sed -r "s/.*href=\"(.+)\".*/\1/" | sed "s/\".*//")"
}

# arg1: link to the episode's page
get_wayback_page() {
    echo "$(curl -s "http://archive.org/wayback/available?url=$1" | sed -r "s/.*\"url\":\"(.*)\".*/\1/" | sed "s/\".*//")"
}

# Same as get_url() but works for openload links
# Not needed anymore, but keep it in case it changes back in future.
# arg1: link to the episode's page
get_url_openload() {
    get_url "$1"
    # echo "$(curl -s "$1" | grep -i "bs.to/out" | sed -r "s/.*src='(.+)'.*/\1/" | sed "s/'.*//")"
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
    log "Downloading" "$2 ( $1 )"
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

# arg1: prefix
# arg2: text
log() {
    local BLUE="$(tput setaf 4)"
    local RESET="$(tput sgr0)"
    echo -e "\n${BLUE}[$1]$RESET $2"
}

check_cef_available() {
    if ! which cefget.py > /dev/null; then
        return 1
    elif ! pip3 freeze | grep cefpython > /dev/null; then
        return 1
    fi
    return 0
}

# arg1: url
# arg2: hoster
prompt_captcha() {
    local HOSTER="$2"

    # OpenloadHD links resolve back to openload
    if [[ "${2,,}" == "openloadhd" ]]; then
        HOSTER=openload
    fi

    if [[ "$1" =~ bs.to/out/.* ]]; then
        local NEWURL
        NEWURL="$(cefget.py "$1" "$HOSTER")"
        if [[ $? -eq 0 ]]; then
            echo "$NEWURL"
            return
        fi
    fi
    echo "$1"
}

# Download the page and extract each episode's link
# arg1: season link
# arg2: hoster
extract_episodes() {
    local SRC="$(curl -s "$1" | grep -i "$2" | grep -i href | sed -r "s/.*href=\"(.+)\".*/\1/")"

    # There's another hoster OpenloadHD that needs to be filtered out if the
    # desired hoster is the normal Openload
    if [[ "${2,,}" == "openload" ]]; then
        echo "$SRC" | grep -vi openloadhd
    else
        echo "$SRC"
    fi
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

    local HOSTER="$2"
    local SRC="$(extract_episodes "$1" "$HOSTER")"
    shift 2

    local INVERT=false
    local PARALLEL=false
    local EXTRACTONLY=0
    local MAXDOWNLOADS=4
    local SKIP=true
    local EPISODES=
    local STARTAT=
    local WAYBACK=false
    local WAYBACK_HOSTER=false
    local PROMPT_LAZY=false
    local SLEEP=0

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
            -r )
                SKIP=false
                ;;
            -m )
                MAXDOWNLOADS=$2
                shift
                ;;
            -ss )
                if [[ -z "$EPISODES" ]]; then
                    STARTAT="$2"
                else
                    echo "Warning: \"-ss $2\" has no effect because -e is present."
                fi
                shift
                ;;
            -e )
                EPISODES="$2"
                if [[ -n "$STARTAT" ]]; then
                    echo "Warning: \"-ss $STARTAT\" has no effect because -e is present."
                    STARTAT=
                fi
                shift
                ;;
            -v )
                INVERT=true
                ;;
            -w )
                WAYBACK=true
                ;;
            -wh )
                WAYBACK_HOSTER=true
                ;;
            -a )
                PROMPT_LAZY=true
                ;;
            -s )
                SLEEP=$2
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

    # Extract URLs
    URLS=()
    NAMES=()
    local CEFAVAIL=true
    if ! check_cef_available; then
        CEFAVAIL=false
        echo "CEF (Chromium Embedded Framework) captcha popup not available."
    fi

    while read -r line; do
        local PAGE="https://bs.to/$line"
        if $WAYBACK; then
            PAGE="$(get_wayback_page "$PAGE")"
        fi

        local NAME="$(get_name "$PAGE")"

        # Should the current episode be downloaded?
        if [[ -n "$EPISODES" ]]; then
            # Continue to next episode if not in (inverted) list
            if [[ ",${EPISODES}," == *",${NAME%%-*},"* ]]; then
                $INVERT && continue
            else
                $INVERT || continue
            fi
        elif [[ -n "$STARTAT" ]]; then
            if [[ ${NAME%%-*} -ge $STARTAT ]]; then
                $INVERT && continue
            else
                $INVERT || continue
            fi
        fi

        if [[ $EXTRACTONLY -eq 0 ]]; then
            log "Extracting" "$NAME"
        fi

        # Videos hosted on openload are embeded directly in the page and
        # thus need to be handled differently.
        if [[ "${HOSTER,,}" == "openload" ]]; then
            local URL="$(get_url_openload "$PAGE")"
        else
            local URL="$(get_url "$PAGE")"
        fi

        if $WAYBACK; then
            if $WAYBACK_HOSTER; then
                URL="http://web.archive.org$URL"
            else
                URL="${URL#/web/*/}"
            fi
        fi

        # Prompt the user to solve the captcha
        # Untested with wayback machine
        if ! $PROMPT_LAZY && $CEFAVAIL; then
            if [[ $SLEEP -gt 0 ]]; then
                echo "Waiting $SLEEP seconds"
                sleep $SLEEP
            fi
            URL="$(prompt_captcha "$URL" "$HOSTER")"
        fi

        # Print or store URL for downloading
        if [[ $EXTRACTONLY -eq 1 ]]; then
            youtube-dl -g "$URL"
        elif [[ $EXTRACTONLY -eq 2 ]]; then
            echo "$URL"
        else
            URLS+=("$URL")
            NAMES+=("$NAME")
        fi
    done <<< "$SRC"

    # Download
    if [[ $EXTRACTONLY -eq 0 ]]; then
        for i in "${!URLS[@]}"; do
            if $PARALLEL; then
                until [[ $(num_downloads) -lt $MAXDOWNLOADS ]]; do
                    sleep 1
                done
            fi

            local url="${URLS[$i]}"
            if $PROMPT_LAZY && $CEFAVAIL; then
                url="$(prompt_captcha "$url" "$HOSTER")"
            fi

            if $PARALLEL; then
                inc_downloads +1
                download_p "$url" "${NAMES[$i]}" $SKIP &
            else
                download "$url" "${NAMES[$i]}" $SKIP
            fi
        done
    fi
}

main "$@"
