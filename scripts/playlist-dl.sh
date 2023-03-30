#!/usr/bin/env bash
yt-dlp "$1" -x --audio-format mp3 -N 4 -o "%(playlist_index)s - %(title)s.%(ext)s"
