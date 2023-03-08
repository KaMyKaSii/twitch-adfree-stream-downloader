#!/bin/bash
wait_time=310
date="$(date "+%H-%M-%S")"
tmp_file="$(mktemp)"
ffmpeg_bin="ffmpeg"
opt="-thread_queue_size 52428800"
container="mkv"

trap "exitting" EXIT

exitting() {
	if [ -n "$(cat ${tmp_file})" ]; then
		echo -e "\nThe stream has come to an end!"
		if command -v notify-send 1>/dev/null; then
			notify-send -t 10000 "The stream has come to an end!"
		fi
	fi
	rm -f "${tmp_file}"
}

CheckRequirements() {
	for programrequirement in python3 "${ffmpeg_bin}"; do
		if ! command -v ${programrequirement} 1>/dev/null; then
			echo -e "${programrequirement} could not be found, install it with:
apt install ${programrequirement}"
			exit 1
		fi
	done
	if command -v yt-dlp 1>/dev/null; then
		ytdl_bin=$(command -v yt-dlp)
	elif command -v youtube-dl 1>/dev/null; then
		ytdl_bin=$(command -v youtube-dl)
	else
		echo "You need to install yt-dlp (https://github.com/yt-dlp/yt-dlp) or youtube-dl (https://github.com/ytdl-org/youtube-dl). Choose one and replace it in the command below to install it:
\"python3 -m pip install -U [CHOICE]\""
		exit 1
	fi
}

check_connection() {
	until curl -Ifs https://www.google.com 1> /dev/null; do
		sleep 5
	done
}

get_segments() {
	if [ -n "${local_file}" ]; then
		sed -n "/EXTINF:/ {n;p}" "${playlist}"
	else
		curl -s "${playlist}" | sed -n "/EXTINF:/ {n;p}"
	fi
}

config_file() {
	rm -f "${tmp_file}"
	if [ -n "${local_file}" ]; then
		for segment in ${segments_to_download[@]}; do
			echo "url=\"${segment}\"" >> "${tmp_file}"
		done
	else
		for segment in ${segments_to_download[@]}; do
			echo "url=\"${path}/${segment}\"" >> "${tmp_file}"
		done
	fi
	#cat "${tmp_file}" >> "${logfile}"
}

download_segments() {
	curl -s -f -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36' -H 'Accept-Encoding: gzip, deflate, br' -K "${tmp_file}"
}

sleep_time() {
	if [ ${time_elapsed} -lt ${wait_time} ]; then
		time_to_sleep=$((wait_time - time_elapsed))
		until [ ${time_to_sleep} -eq 0 ]; do
			echo >&2 -ne "\rSleeping for ${time_to_sleep} seconds...\e[K"
			let "time_to_sleep=time_to_sleep-1"
			sleep 1
		done
	fi
	echo >&2 -ne "\r\e[K"
}

CheckRequirements

if [ -f "${1}" ]; then
	local_file=1
	playlist="${1}"
	path="$(dirname $(sed -n "/EXTINF:/ {n;p}" "${playlist}" | head -1))"
elif [[ ${1} == *".m3u8"* ]]; then
	playlist="${1}"
	path="$(dirname "${playlist}")"
else
	playlist=$("${ytdl_bin}" "${1}" -g 2> /dev/null)
	if [[ ${playlist} != *".m3u8"* ]]; then
		echo "The link is not a hls playlist."
		exit 1
	fi
	path="$(dirname "${playlist}")"
fi

read -rep $'Type the output filename:\n>>> ' name
perl -MPOSIX -e 'tcflush 0,0'
read -rep $'Do you want to change the output folder? Type \"y\" to confirm or anything else to leave the default.\n>>> ' -r choice
if [ "${choice^^}" == "Y" ]; then
	perl -MPOSIX -e 'tcflush 0,0'
	read -rep $'Type output folder path:\n>>> ' -r download_dir
	download_dir="${download_dir}/livestream-from-start"
else
	download_dir="${HOME}/livestream-from-start"
fi
mkdir -p "${download_dir}"
#logfile="${download_dir}/${name}-${date}.log"
echo ""

segments_to_download=(empty)
while true; do
	start=${SECONDS}
	check_connection
	segments=($(get_segments))
	segments_to_download="${segments[@]:continue}"
	if [ -z "${segments_to_download}" ]; then
		break
	fi
	continue=${#segments[@]}
	config_file
	check_connection
	download_segments
	time_elapsed=$((SECONDS - start))
	sleep_time
done | "${ffmpeg_bin}" -y -hide_banner -stats -v warning ${opt} -f mpegts -i pipe: -c copy "${download_dir}/${name}.${container}"