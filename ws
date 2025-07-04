#!/bin/sh
# Jon Ward, 2025.
# Open URLs and/or search queries in the web browser.

# # Suppress output (e.g. errors from cmd.exe)
# exec 1>/dev/null 2>/dev/null

if is-wsl; then
	BROWSER='cmd.exe /C start ""'
else
	BROWSER=${BROWSER:-firefox}
fi

SEARCH_ENGINE="${SEARCH_ENGINE:-https://duckduckgo.com/?q=}"
# SEARCH_ENGINE="${SEARCH_ENGINE:-https://www.google.com/search?q=}"

is_url() {
	case "$1" in
		http://*|https://*) return 0 ;;
		*) return 1 ;;
	esac
}

open_browser() {
	set -- $BROWSER "$1"
	"$@"
}

ws() {
	for arg in "$@"; do
		if is_url "$arg"; then
			open_browser "$arg"
		else
			# Replace spaces with '+' for search queries
			query=$(printf '%s' "$arg" | sed 's/ /+/g')

			query=$(urlencode "$arg")
			open_browser "${SEARCH_ENGINE}${query}"
		fi
	done
}

ws "$@"

