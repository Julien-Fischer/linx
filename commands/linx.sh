#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
else
    echo "E: Could not source ${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

# doc

USAGE=$(cat <<EOF
Usage: linx [OPTIONS]

Backup the element identified by the specified path. If the element to backup is
a directory, copy it recursively.

Arguments:
  sync                    Synchronize the local setup with the remote

Options:
  -c, --commands          List the native Linx commands
  -d, --dir               Print the absolute path to linx work directory
  -g, --go                Navigate to linx work directory
  -h, --help              Show this message and exit
  -v, --version           Show Linx version and exit
EOF
)

pull_setup() {
    if install_core; then
        echo "${PROJECT} successfully synced"
    else
        echo "${PROJECT}: failed to sync"
        return 1
    fi
}

# @description Synchronize the local linx installation with the latest version from the remote
# @return 0 if the configuration was synchronized successfully; 1 otherwise
linx() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            sync)
                pull_setup
                return 0
                ;;
            -v|--version)
                echo "${VERSION}"
                return 0
                ;;
            -h|--help)
                echo "${USAGE}"
                return 0
                ;;
            -c|--commands)
                cat "${LINX_INSTALLED_COMMANDS}"
                return 0
                ;;
            -d|--dir)
                echo "${LINX_DIR}"
                return 0
                ;;
            -g|--go)
                cs "${LINX_DIR}"
                return 0
                ;;
            *)
                err "Invalid parameter ${1}"
                echo "${USAGE}"
                return 1
                ;;
        esac
    done
}

linx "$@"