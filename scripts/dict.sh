#!/bin/bash
# Dictionary file can be downloaded from http://www1.dict.cc/translation_file_request.php
DICTPATH="/home/marvin/dict.cc/cbdobbnsbm-178274069-e96o85.txt"
cat "$DICTPATH" | fzf --tabstop=16 --reverse -d $'\t' -n 1,2 --header=$'DE\tEN' --bind 'ctrl-p:execute(echo -e {} | less)'
