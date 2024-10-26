#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/.linx_lib.sh ]]; then
    source "${HOME}"/.linx_lib.sh
fi
source "${HOME}"/.bashrc

# @description Synchronize the local linx installation with the latest version from the remote
# @return 0 if the configuration was synchronized successfully; 1 otherwise
linx() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            sync)
                if install_core; then
                    echo "${PROJECT} successfully synced"
                else
                    echo "${PROJECT}: failed to sync"
                    return 1
                fi
                shift
                return 0
                ;;
            -v|--version)
                echo "${VERSION}"
                return 0
                ;;
            *)
                shift
                ;;
        esac
    done
    echo "Usage: linx [sync|--version]"
    return 1
}

linx "$@"