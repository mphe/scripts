#!/usr/bin/env bash

if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo -e "Usage:\n"
    echo -e "\t$0 branch branch_to"
    echo -e "\t$0 branch_to"
    echo "Merge first branch into second branch."
    echo "If only one branch is given, merge the current active branch into the given branch."
    exit
fi

FROM="$1"
TO="$2"

# Only one argument given?
if [ -z "$TO" ]; then
    FROM="$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)"
    TO="$1"
fi

git checkout "$TO" && git merge "$FROM"
# git checkout "$FROM"
