#!/usr/bin/env bash

TMPDIR=

cleanup() {
	if [ -n "$TMPDIR" ]; then
		echo "Cleanup up temporary directory"
		rm -r "$TMPDIR"
	fi
}

main() {
	local pdf="$1"
	local out_pdf="$2"
	shift 2

	if [ -z "$pdf" ] || [ -z "$out_pdf" ]; then
		echo "Error: Invalid syntax"
		echo "Rasterizes a PDF to jpeg and generates a new PDF from it."
		echo "Usage: ${0##*/} <Input PDF path> <Output PDF path>"
		exit 1
	fi

	pdf="$(realpath "$pdf")"
	out_pdf="$(realpath "$out_pdf")"

	trap cleanup 0               # EXIT
	trap "cleanup; exit 1" 2     # INT
	trap "cleanup; exit 1" 1 15  # HUP TERM

	echo "Creating temporary directory..."
	TMPDIR="$(mktemp -d "/tmp/pdftoimgpdf.XXXXXXX")"
	cd "$TMPDIR" || exit 1

	echo "Converting PDF to images..."
	pdftoppm -jpeg -r 300 "$pdf" "page"

	echo "Converting images to PDF..."
	convert page* "$out_pdf"
}

main "$@"
