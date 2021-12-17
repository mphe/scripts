#!/usr/bin/env bash

if [ -n "$1" ]; then
    faillock --user "$1" --reset
else
    echo Error: No user given
fi
