#!/usr/bin/env bash
# Add youtube playlist to MPD

# shellcheck disable=SC2155

MAXJOBS='200%'  # all cores
MPD_DIR=~/Musik
OUTDIR=stream

# arg1: json string
# arg2: query
json_get() {
    echo "$1" | jq "$2" | sed -E 's/(^"|"$)//g'
}

main()
{
    echo Fetching playlist title...
    local pl_title="$(youtube-dl --skip-download --playlist-end 1 "$1" | grep 'Downloading playlist: ' | sed 's/.*: //')"

    echo Fetching URLs...
    local json="$(youtube-dl -jix --flat-playlist "$1")"
    local urls="$(json_get "$json" ".url" | parallel --jobs $MAXJOBS --keep-order --bar 'youtube-dl -gxi "https://youtu.be/{1}"')"

    echo Generating playlist...
    local mpdname="$OUTDIR/$pl_title.m3u"
    local fname="$MPD_DIR/$mpdname"
    mkdir -p "$MPD_DIR/$OUTDIR"

    echo "#EXTM3U" > "$fname" || exit 1  # Abort if not writable

    while IFS= read -r line; do
        local title="$(json_get "$line" ".title")"
        local duration="$(json_get "$line" ".duration")"
        local url="$(echo "$urls" | head -n 1)"
        urls="$(echo "$urls" | tail -n +2)"

        echo "#EXTINF:$duration,$title" >> "$fname"
        echo "$url" >> "$fname"
    done < <(echo "$json")

    echo

    echo Adding to MPD...
    mpc --wait update "$mpdname"
    mpc load "$mpdname"

    echo -e "\nPlaylist written to $fname and added to MPD queue"
}

main "$@"
