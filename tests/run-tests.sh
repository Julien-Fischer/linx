#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

################################################################
# Constants
################################################################

build_name=linx-tests
dockerfile_directory=..

################################################################
# Cleanup
################################################################

clear

if [[ $(docker ps -q -f name=$build_name) ]]; then
    docker stop $build_name
fi

if [[ $(docker ps -qa -f name=$build_name) ]]; then
    docker rm $build_name
fi

if [[ $(docker images -q name=$build_name) ]]; then
    docker rmi $build_name
fi

################################################################
# Build image and run tests
################################################################

docker build -t $build_name $dockerfile_directory
docker run --name $build_name $build_name


# Inspect the container via the CLI:
# docker exec -ti "mkf-tests" /bin/bash