#!/usr/bin/env bash
grep -r -m 1 "^" .  2>&1 | grep "binary file matches" | sed -r 's/grep: //' | sed 's/: binary file matches//' | sed -r 's/.*\.(.+)$/\1/' | sort | uniq | xargs -I '{}' git lfs track "*.{}"
