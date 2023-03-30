#!/usr/bin/env bash

if [ $# -lt 2 ]; then
	echo "Rotate an image (default: 90°)."
	echo "Usage: $0 <input> <output> [rotation degrees]"
	exit 1
fi

convert "$1" -rotate "${3:-90}" "$2"
