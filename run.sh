#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPODIR="$(dirname "$SCRIPTDIR")"

# always fail script if a cmd fails
set -eo pipefail

# Remove arkmanager tracking files if they exist
# They can cause issues with starting the server multiple times
# due to the restart command not completing when the container exits
echo "Cleaning up any leftover arkmanager files..."
[ -f /ark/server/ShooterGame/Saved/.ark-warn-main.lock ] && rm -rf /ark/server/ShooterGame/Saved/.ark-warn-main.lock
[ -f /ark/server/ShooterGame/Saved/.ark-update.lock ] && rm -rf /ark/server/ShooterGame/Saved/.ark-update.lock
[ -f /ark/server/ShooterGame/Saved/.ark-update.time ] && rm -rf /ark/server/ShooterGame/Saved/.ark-update.time
[ -f /ark/server/ShooterGame/Saved/.arkmanager-main.pid ] && rm -rf /ark/server/ShooterGame/Saved/.arkmanager-main.pid
[ -f /ark/server/ShooterGame/Saved/.arkserver-main.pid ] && rm -rf /ark/server/ShooterGame/Saved/.arkserver-main.pid
[ -f /ark/server/ShooterGame/Saved/.autorestart ] && rm -rf /ark/server/ShooterGame/Saved/.autorestart
[ -f /ark/server/ShooterGame/Saved/.autorestart-main ] && rm -rf /ark/server/ShooterGame/Saved/.autorestart-main

# Create directories if they don't exist
[ ! -d /ark/config ] && mkdir /ark/config
[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/staging ] && mkdir /ark/staging

echo "Creating arkmanager.cfg from environment variables..."
echo -e "# Ark Server Tools - arkmanager config\n# Generated from container environment variables\n\n" > /ark/config/arkmanager.cfg
if [ -f /ark/config/arkmanager_base.cfg ]; then
	cat /ark/config/arkmanager_base.cfg >> /ark/config/arkmanager.cfg
fi

echo -e "\n\narkserverroot=\"/ark/server\"\n" >> /ark/config/arkmanager.cfg
printenv | sed -n -r 's/am_(.*)=(.*)/\1=\"\2\"/ip' >> /ark/config/arkmanager.cfg

if [ ! -d /ark/server ] || [ ! -f /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer ]; then
	echo "No game files found. Installing..."
	mkdir -p /ark/server/ShooterGame/Saved/SavedArks
	mkdir -p /ark/server/ShooterGame/Saved/Config/LinuxServer
	mkdir -p /ark/server/ShooterGame/Content/Mods
	mkdir -p /ark/server/ShooterGame/Binaries/Linux/
fi

su -p - root -c /arkserver/cron.sh

# Create symlinks for configs
[ -f /ark/config/AllowedCheaterSteamIDs.txt ] && ln -sf /ark/config/AllowedCheaterSteamIDs.txt /ark/server/ShooterGame/Saved/AllowedCheaterSteamIDs.txt
[ -f /ark/config/Engine.ini ] && ln -sf /ark/config/Engine.ini /ark/server/ShooterGame/Saved/Config/LinuxServer/Engine.ini
[ -f /ark/config/Game.ini ] && ln -sf /ark/config/Game.ini /ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini
[ -f /ark/config/GameUserSettings.ini ] && ln -sf /ark/config/GameUserSettings.ini /ark/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini

if [[ "$VALIDATE_SAVE_EXISTS" = true && ! -z "$am_ark_AltSaveDirectoryName" && ! -z "$am_serverMap" ]]; then
	savepath="/ark/server/ShooterGame/Saved/$am_ark_AltSaveDirectoryName"
	savefile="$am_serverMap.ark"
	echo "Validating that a save file exists for $am_serverMap"
	echo "Checking $savepath"
	if [[ ! -f "$savepath/$savefile" ]]; then
		echo "$savefile not found!"
		echo "Attempting to notify via Discord..."
		arkmanager notify "Critical error: unable to find $savefile in $savepath!"

		# wait on failure so we don't spam docker logs
		sleep 5m
		exit 1
	else
		echo "$savefile found."
	fi
else
	echo "Save file validation is not enabled."
fi

if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks/)" ]; then 
    echo "[Backup on Start]"
    arkmanager backup
else
    echo "[No Backup On Start]"
fi

function stop {
	if [ ${BACKUPONSTOP} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks)" ]; then
		echo "[Backup on stop]"
		arkmanager backup
	fi
	if [ ${WARNONSTOP} -eq 1 ];then 
            arkmanager broadcast "Server is shutting down"
            arkmanager notify "Server is shutting down"
	    arkmanager stop --warn
	else
            arkmanager broadcast "Server is shutting down"
            arkmanager notify "Server is shutting down"
	    arkmanager stop
	fi
	exit 0
}

# Stop server in case of signal INT or TERM
trap stop INT
trap stop TERM

# TODO: Provide IF statement here with ENV variable
# to allow server logs to be scraped from RCON to stdout
# bash -c ./log.sh &

arkmanager start --no-background --verbose &
arkmanpid=$!
wait $arkmanpid
