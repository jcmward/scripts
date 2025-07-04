#!/bin/sh
# Jon Ward, 2025.
# `mpv` wrapper to recursively play all files in given directories.

MEDIA_PLAYER="${MEDIA_PLAYER:-mpv}"

m() {
	if [ "$#" -eq 0 ]; then
		set -- "."
	fi

	tmpfile=$(mktemp)

	# Collect and sort filenames
	if [ "$FD_CMD" = "fdfind" ] || [ "$FD_CMD" = "fd" ]; then
		for dir in "$@"; do
			"$FD_CMD" . "$dir" --type f --print0
		done
	else
		for dir in "$@"; do
			find "$dir" -type f -print0
		done
	fi | sort -Vfuz > "$tmpfile"

	# If files were found, play them
	if [ -s "$tmpfile" ]; then
		xargs -0 "$MEDIA_PLAYER" < "$tmpfile" > /dev/null 2>&1 &
	else
		printf "No files found.\n"
	fi

	rm -f "$tmpfile"
}

m "$@"

