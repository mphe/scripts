#!/usr/bin/env bash

FILENAME=""

ask_filename() {
	read -r -p "File name: " FILENAME

	if [[ "$FILENAME" != *.patch ]]; then
		FILENAME="$FILENAME.patch"
	fi
}

echo "Select one of the following options"
echo "1) Current diff"
echo "    git diff --no-prefix" "$@"
echo
echo "2) Last commit"
echo "    git format-patch -1" "$@"
echo
echo "3) Last commit (same as 2?)"
echo "    git show --no-prefix" "$@"
echo

read -r -p "Selection: " selection

case "$selection" in
	1 )
		ask_filename
		git diff --no-prefix "$@" | tee "$FILENAME"
		;;
	2 )
		git format-patch -1 "$@"
		;;
	3 )
		ask_filename
		git show --no-prefix "$@" | tee "$FILENAME"
		;;
	* )
		echo "Invalid choice"
		exit 1
		;;
esac

