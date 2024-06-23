#!/bin/bash

# Specify the name of your Docker container
CONTAINER_NAME="minecraft-server-minecraft-server-1"

# Check if the container is running
if [ "$(docker inspect -f '{{.State.Running}}' $CONTAINER_NAME 2>/dev/null)" == "true" ]; then
    echo "Container $CONTAINER_NAME is running, will not restore."
    cd .
    docker compose up
else
    echo "Container $CONTAINER_NAME is not running, will restore."
    cd ./restore
    docker compose up
    sleep 10
    cd ../
    docker compose up
fi
