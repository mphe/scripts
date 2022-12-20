#!/usr/bin/env bash

main() {
	local pdf="$1"
	local out_pdf="$2"
	shift 2

	if [ -z "$pdf" ] || [ -z "$out_pdf" ]; then
		echo "Error: Invalid syntax"
		echo "Usage: ${0##*/} <Input PDF path> <Output PDF path>"
		echo
		echo "Compresses a PDF containing images."
		echo "See also https://unix.stackexchange.com/questions/274428/how-do-i-reduce-the-size-of-a-pdf-file-that-contains-images"
		exit 1
	fi

	gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -q -o "$out_pdf" "$pdf"
}

main "$@"
