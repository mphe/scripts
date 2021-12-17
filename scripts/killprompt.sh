#!/usr/bin/env bash
DIRNAME="$(dirname "$(readlink -f "$0")")"
PID=$("$DIRNAME/getpid.sh")
echo "$PID"
kill -9 "$@" "$PID"
