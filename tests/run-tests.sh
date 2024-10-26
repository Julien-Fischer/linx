#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

################################################################
# Constants
################################################################

BUILD_NAME=linx-tests
DOCKER_FILE_DIR=..

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
docker run --name $BUILD_NAME $BUILD_NAME


# Inspect the container via the CLI:
#docker exec -ti "$BUILD_NAME" /bin/bash