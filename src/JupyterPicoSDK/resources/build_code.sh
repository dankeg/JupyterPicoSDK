#!/bin/bash

# Start the Dev Container
devcontainer up --workspace-folder .

sleep 5

docker ps -a

# Get the container name
CONTAINER_NAME=$(docker ps --filter "ancestor=ghcr.io/nu-horizonsat/pico-sdk-docker:main@sha256:d4c3a5fbada696df53228411f11ce6238c97717b5256d625eb1bba0739ef1823" --format "{{.Names}}")

# Run the build inside the container
docker exec $CONTAINER_NAME bash -c "cd /workspaces/JupyterPicoSDK && mkdir -p build && cd build && cmake .. && make && touch test"

# Continue with the workflow
echo "Build completed inside the Dev Container."

