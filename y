#!/bin/sh
# Jon Ward, 2025.
# yt-dlp wrapper.

# OPTIONS LEGEND
# y	video
# y -a	audio
# y -b	edit batch file with $VISUAL, then run
# y -f	force: ignore download archive
# y -i	thumbnail image
# y -n	ignore batch file

# TODO: test and debug

ytdlp_channel() {
	# Create URL for channel playlists
	playlists_url="${1}/playlists"
	ytdlp_opts='--download-archive "$HOME/.config/yt-dlp/archive" --no-batch-file'

	# Download playlists
	# Using `|| true` to avoid error for channels without playlists tab
	yt-dlp $ytdlp_opts --output "$YTDLP_DIR/%(uploader)s/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s" "${@:2}" "$playlists_url" || true

	# Download loose/new videos that aren't included in any playlists
	yt-dlp $ytdlp_opts --output "$YTDLP_DIR/%(uploader)s/No_Playlist/%(title)s.%(ext)s" "${@:2}" "$1"

	printf "\nDone.\n\n"
}

y() {
	if [ $# -eq 0 ]; then
		printf "Usage: %s [URL] [yt-dlp options]\n" "$0"
		return 1
	elif ! command -v yt-dlp >/dev/null 2>&1; then
		printf "yt-dlp is not installed. Please install it first.\n"
		return 1
	elif [ -z "${YTDLP_DIR}" ]; then
		printf "Error: YTDLP_DIR environment variable is undefined.\n"
		return 1
	fi

	if [ ! -d "${YTDLP_DIR}" ]; then
		mkdir -p "${YTDLP_DIR}"
		printf "Failed to create YTDLP_DIR: %s\n" "$YTDLP_DIR"
		return 1
	fi

	if ! cd "${YTDLP_DIR}"; then
		return 1
	fi

	audio_config="${XDG_DATA_HOME:-~/.local/share}/yt-dlp/batch"
	batch_file="${XDG_DATA_HOME:-~/.local/share}/yt-dlp/batch"
	ytdlp_opts=""
	exec_first=""

	OPTIND=1
	while getopts "abin" opt; do
		case "${opt}" in
			a)
				ytdlp_opts="$ytdlp_opts --config-location $audio_config"
				;;
			b)
				ytdlp_opts="$ytdlp_opts --batch-file $batch_file"
				exec_first="$VISUAL $batch_file"
				;;
			f)
				ytdlp_opts="$ytdlp_opts --no-download-archive"
				;;
			i)
				ytdlp_opts="$ytdlp_opts --skip-download --write-thumbnail"
				;;
			n)
				ytdlp_opts="$ytdlp_opts --no-batch-file"
				;;
		esac
	done
	shift "$((OPTIND - 1))"

	# Edit the batch file, if required
	if [ -n "$exec_first" ]; then
		eval "$exec_first"
	fi

	for arg in "$@"; do
		channel="false"

		# Determine if URL is for a channel
		case "$arg" in
			*"@"*)
				channel="true"
				;;
		esac

		# Double-check: if it has one of these suffixes, it's a channel URL
		suffixes="/community /featured /live /playlists /podcasts /releases /shorts /store /streams /videos"
		for suffix in $suffixes; do
			case "$arg" in
				*"$suffix")
					# Truncate channel URL as needed
					arg="${arg%"$suffix"}"
					channel="true"
					break
					;;
			esac
		done

		if [ "$channel" = "true" ]; then
			ytdlp_channel "$arg" ${ytdlp_opts:+$ytdlp_opts}
		else
			yt-dlp $ytdlp_opts "$arg"
		fi
	done
}

y "$@"

