#!/bin/bash

#Sets defualt values if not specified
BACKUP_INTERVAL="${BACKUP_INTERVAL:-30m}" #30 minute default interval has to be in minutes
BACKUP_METHOD="${BACKUP_METHOD:-tar}" #Tar
BACKUP_NAME="${BACKUP_NAME:-MC-SERVER-BACKUP}" #Backup Name
INITIAL_DELAY="${INITIAL_DELAY:-5m}" #Initial wait
RCON_HOST="${RCON_HOST:-minecraft-server}"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:-rcon}"
PRUNE_BACKUP_DAYS="${PRUNE_BACKUP_DAYS:-7}" #When to delete backups
SERVER_PORT="${SERVER_PORT:-"25565"}"
DEST_DIR="${DEST_DIR:-/backups}"
SRC_DIR="${SRC_DIR:-/data}"
PLUGIN_DIR="${PLUGIN_DIR:-/plugins}"

# Function to sleep scripts
script_sleep() {
	local time="$1"
	sleep $time
}

# Function to send RCON commands
send_rcon_command() {
	local command="$1"
	/opt/rcon-cli --host $RCON_HOST --port $RCON_PORT --password $RCON_PASSWORD $command > /dev/null
}

# Function that will retrieve mc world from volume

do_file_things() {
	rm -rf /mc-bk && mkdir /mc-bk && cd /mc-bk
	current_date_time=$(date +"%Y-%m-%d_%H-%M-%S")
	filename="${BACKUP_NAME}-${current_date_time}.tar.gz"
	mkdir data
	cp -r $SRC_DIR/main_world /mc-bk/data
	#cp -r $PLUGIN_DIR/Multiverse-Inventories /mc-bk$SRC_DIR$PLUGIN_DIR
	# Remove unnessesary files
	#rm -rf /mc-bk/data/bundler /mc-bk/data/cache /mc-bk/data/libraries /mc-bk/data/versions
	echo "Compressing world"
	tar -czvf "$filename" /mc-bk  > /dev/null
	echo "Complete! Moving world to backup folder..."
	mv "$filename" "$DEST_DIR"
	cd / && rm -rf /mc-bk
}

# Function in case of crash/ docker killed
cleaup() {
	echo "Shutting down"
	/opt/rcon-cli --host $RCON_HOST --port $RCON_PORT --password $RCON_PASSWORD "save-on" > /dev/null
	exit 0
}

#Extract number from env var and get seconds
BACKUP_INTERVAL_SECONDS=$(( $(echo "$BACKUP_INTERVAL" | grep -o '[0-9]' | tr -d '\n') * 60 ))
INITIAL_DELAY_SECONDS=$(( $(echo "$INITIAL_DELAY" | grep -o '[0-9]' | tr -d '\n') * 60 ))

#Initial Delay
script_sleep $INITIAL_DELAY_SECONDS

#Ensures autosave is always on
trap cleanup SIGTERM

#Main loop
while true
do
	# Sleeps the script for the specified interval
	script_sleep $BACKUP_INTERVAL_SECONDS
	# Check server is running
	#if ! docker ps --format '{{.Names}}' | grep -q "^${RCON_HOST}$"; then
	#	echo "Server is down, exiting"
	#	break
	#fi
	# Turns off autosave
	send_rcon_command "save-off"
	# Saves the game
	send_rcon_command "save-all flush"
	script_sleep 1
	# Backs up the world and moves it to backups
	do_file_things
	# Turns autosave back on
	send_rcon_command "save-on"
	echo "Prune Old Backups"
	find "$DEST_DIR" -type f -mtime +$(expr $PRUNE_BACKUP_DAYS - 1) -exec rm {} \;
	echo "Backup Complete!, Sleeping "$BACKUP_INTERVAL""
done
