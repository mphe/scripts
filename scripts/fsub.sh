#!/bin/bash
A="$1"
B="$2"
shift 2
if [[ -z "$@" ]]; then
    find . -type f -exec sed -i -r "s/$A/$B/g" {} +
else
    find "$@" -type f -exec sed -i -r "s/$A/$B/g" {} +
fi

