#!/usr/bin/env bash
DIRNAME="$(dirname "$(readlink -f "$0")")"
kill "$@" $("$DIRNAME/getpid.sh")
