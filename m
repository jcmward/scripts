#!/bin/sh
# Jon Ward, 2025.
# `mpv` wrapper to recursively play all files in given directories.

MEDIA_PLAYER="${MEDIA_PLAYER:-mpv}"

convert_path() {
	if command -v wslpath >/dev/null 2>&1; then
		wslpath -w "$1" 2>/dev/null || printf "%s" "$1"
	else
		printf "%s" "$1"
	fi
}

m() {
	if [ "$#" -eq 0 ]; then
		set -- "."
	fi

	if command -v wslpath >/dev/null 2>&1; then
		tmp_dir="/mnt/c/tmp"
		mkdir -p "$tmp_dir"
	else
		tmp_dir="/tmp"
	fi
	tmpfile=$(mktemp -p "$tmp_dir")

	trap 'rm -f -- "$tmpfile"' EXIT

	for path in "$@"; do
		if [ -d "$path" ]; then
			# Handle directories
			if [ "$FD_CMD" = "fdfind" ] || [ "$FD_CMD" = "fd" ]; then
				"$FD_CMD" . "$path" --type f --print0 | while IFS= read -r file; do
					convert_path "$file"
				done
			else
				find "$path" -type f -print0 | while IFS= read -r file; do
					convert_path "$file"
				done
			fi
		elif [ -f "$path" ]; then
			# Handle regular files
			path=$(convert_path "$path")
			printf "%s\n" "$path"
		else
			printf "Warning: %s is not a file or directory, skipping.\n" "$path" >&2
		fi
	done | sort -Vfuz |  tr '\0' '\n' > "$tmpfile"

	printf "Playlist contents:\n" >&2
	head -5 "$tmpfile" >&2
	printf "...\n" >&2

	# If files were found, play them
	if [ -s "$tmpfile" ]; then
		tmpfile=$(convert_path "$tmpfile")
		"$MEDIA_PLAYER" --playlist="$tmpfile" &
		wait $!
	else
		printf "No files found.\n"
	fi
}

m "$@"

