#!/bin/bash
# Jon Ward, 2025.
# `mpv` wrapper to handle directories.

MEDIA_PLAYER="${MEDIA_PLAYER:-mpv}"

m() {
	args=()
	for arg in "$@"; do
		if [ -d "$arg" ]; then
			args+=("$arg/*")
		else
			args+=("$arg")
		fi
	done
	"$MEDIA_PLAYER" "${args[@]}" &
}

m "$@"

