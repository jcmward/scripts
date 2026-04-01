#!/bin/sh
# Jon Ward, 2025-2026.
# yt-dlp wrapper.

# OPTIONS
# y		download video
# y -a		download audio
# y -b		edit batch file with $VISUAL, then batch download
# y -i		download only thumbnail image
# y -n		ignore download archive (overriden for channel downloads)
# y -p		download entire playlist
# y -u		update yt-dlp and download nothing

ytdlp_run() {
	yt-dlp \
		${opt_audio:+--config-location "$audio_config"} \
		${opt_image:+--skip-download --write-thumbnail} \
		${opt_no_archive:+--no-download-archive} \
		${opt_playlist:+--yes-playlist} \
		"$@"
}

ytdlp_channel() {
	channel_url="$1"
	shift
	playlists_url="$channel_url/playlists"
	archive="$XDG_DATA_HOME/yt-dlp/archive"

	# Download and organize playlists
	if ! ytdlp_run \
		--download-archive "$archive" \
		--match-filter "channel_id = uploader_id & playlist_title != 'Favorites'"
		--output "$YTDLP_DIR/%(uploader)s/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s" \
		"$playlists_url"
	then
		printf "Warning: failed to fetch playlists (possibly none exist)\n" >&2
	fi

	# Download non-playlist videos (and/or new videos not in the archive)
	ytdlp_run \
		--download-archive "$archive" \
		--match-filter "channel_id = uploader_id" \
		--output "$YTDLP_DIR/%(uploader)s/No_Playlist/%(title)s.%(ext)s" \
		"$channel_url"
}

y() {
	if [ $# -eq 0 ]; then
		printf "Usage: %s [OPTIONS] URL [URL...]\n" "$0"
		return 1
	elif ! command -v yt-dlp >/dev/null 2>&1; then
		printf "Error: yt-dlp is not installed\n" >&2
		return 1
	elif [ -z "$YTDLP_DIR" ]; then
		printf "Error: YTDLP_DIR environment variable is undefined\n" >&2
		return 1
	fi

	mkdir -p "$YTDLP_DIR/audio" || {
		printf "Error: failed to create directory '%s'\n" "$YTDLP_DIR/audio" >&2
		return 1
	}

	XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
	XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
	audio_config="$XDG_CONFIG_HOME/yt-dlp/audio_config"
	batch_file="$XDG_DATA_HOME/yt-dlp/batch"

	opt_audio=""
	opt_batch=""
	opt_image=""
	opt_no_archive=""
	opt_playlist=""

	OPTIND=1 
	while getopts "abinpu" opt; do
		case "${opt}" in
			a) opt_audio="yes" ;;
			b) opt_batch="yes" ;;
			i) opt_image="yes" ;;
			n) opt_no_archive="yes" ;;
			p) opt_playlist="yes" ;;
			u)
				yt-dlp --update
				return
				;;
			\?)
				printf "Error: invalid option '-%s'\n" "$OPTARG" >&2
				return 1
				;;
		esac
	done
	shift $((OPTIND - 1))

	if [ -n "$opt_audio" ]; then
		if [ ! -f "$audio_config" ]; then
			printf "Error: audio config not found: '%s'\n" "$audio_config" >&2
			return 1
		fi
	fi

	if [ -n "$opt_batch" ]; then
		${VISUAL:-vim} "$batch_file"
		ytdlp_run --batch-file "$batch_file"
	fi

	suffixes="/community /featured /live /playlists /podcasts /releases /shorts /store /streams /videos"
	for arg in "$@"; do
		channel=""

		# Determine if $arg is a channel URL
		case "$arg" in
			*youtube.com/@*|*youtube.com/channel/*|*youtube.com/c/*|*youtube.com/user/*)
				channel="true"
				;;
		esac
		for suffix in $suffixes; do
			case "$arg" in
				*"$suffix")
					# Remove suffix from channel URL
					arg="${arg%"$suffix"}"
					channel="true"
					break
					;;
			esac
		done

		if [ -n "$channel" ]; then
			ytdlp_channel "$arg"
		else
			ytdlp_run "$arg"
		fi
	done
	printf "\nDone.\n"
}

y "$@"

