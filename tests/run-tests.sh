#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Execute this script to run the tests in normal, background, or interactive mode

################################################################
# Project constants
################################################################

readonly BUILD_NAME=linx-tests
readonly DOCKER_FILE_DIR=..

################################################################
# Build variables
################################################################
# @value 1 for production; 0 if the container should run in interactive mode
interactive=1
# @value 1 for production; 0 to keep the container running in the background for debugging and live interaction
# If keep_alive=0, you can interact with the container by using:
#     docker exec -ti "$BUILD_NAME" /bin/bash
keep_alive=1

parse_parameters() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -k|--keep-alive)
                keep_alive=0
                shift
                ;;
            -i|--interactive)
                interactive=0
                shift
                ;;
            *)
                echo "Unsupported parameter ${1}"
                echo "Usage: ./run-tests.sh [-ki] [--keep-alive | --interactive]"
                shift
                exit 1
                ;;
        esac
    done
}

parse_parameters "$@"

################################################################
# Cleanup
################################################################

clear

if [[ $(docker ps -q -f name=$BUILD_NAME) ]]; then
    docker stop $BUILD_NAME
fi

if [[ $(docker ps -qa -f name=$BUILD_NAME) ]]; then
    docker rm $BUILD_NAME
fi

if [[ $(docker images -q name=$BUILD_NAME) ]]; then
    docker rmi $BUILD_NAME
fi

################################################################
# Build image and run tests
################################################################

docker build -t $BUILD_NAME $DOCKER_FILE_DIR

if [[ $interactive -eq 0 ]]; then
    docker build --build-arg INTERACTIVE='--interactive' -t $BUILD_NAME $DOCKER_FILE_DIR
    docker run -it --name $BUILD_NAME $BUILD_NAME --interactive
elif [[ $keep_alive -eq 0 ]]; then
    docker build --build-arg KEEP_ALIVE='--keep-alive' -t $BUILD_NAME $DOCKER_FILE_DIR
    docker run -it --name $BUILD_NAME $BUILD_NAME --keep-alive
else
    echo "Running Docker container normally..."
    docker run --name $BUILD_NAME $BUILD_NAME
fi

