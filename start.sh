#!/usr/bin/env bash

# https://www.howtogeek.com/782514/how-to-use-set-and-pipefail-in-bash-scripts-on-linux/
#TODO" https://mywiki.wooledge.org/BashFAQ/105
set -eo pipefail

# $0: current shell or shell script file name
lib="$(dirname $(realpath $0))/lib"

# kill child processes on exit
# https://stackoverflow.com/questions/360201/how-do-i-kill-background-processes-jobs-when-my-shell-script-exits/2173421#2173421
trap 'exit_code=$?; kill -- $(jobs -p); exit $exit_code' SIGINT SIGTERM EXIT

env \
	METRICS_SERVER_PORT=9323 NODE_ENV=production \
	node_modules/.bin/monitor-hafas \
	--trips-fetch-mode on-demand \
	$lib/hafas.js \
	&

env \
	METRICS_SERVER_PORT=9324 NODE_ENV=production LOG_LEVEL=debug \
	node_modules/.bin/match-with-gtfs \
	$lib/hafas-info.js $lib/gtfs-info.js \
	&

env \
	METRICS_SERVER_PORT=9325 NODE_ENV=production \
	node_modules/.bin/serve-as-gtfs-rt \
	--signal-demand \
	--feed-url 'https://vbb-gtfs.jannisr.de/latest/' \
	&

# fail if any child process failed, running into the trap above
# Note: `wait` (without any flags) waits for *all* child processes to finish. Bash 5.0 introduced `wait -n`, which only waits until *one* job has exited. macOS bundles bash 3.2. 🙄
wait -n || exit 1
