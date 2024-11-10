#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# @param $1 the path of the file to source, relative to $HOME
require_source() {
    local filepath="${1}"
    if [[ -f "${HOME}/${filepath}" ]]; then
        # shellcheck source=src/util.sh
        source "${HOME}/${filepath}"
    else
        echo "E: Could not source ${HOME}/${filepath}"
    fi
}

require_source "/linx/.linx_lib.sh"
require_source "/linx/linx.sh"
require_source ".bashrc"

# doc

USAGE=$(cat <<EOF
Usage: linx [OPTIONS]

Backup the element identified by the specified path. If the element to backup is
a directory, copy it recursively.

Arguments:
  s, sync                 Synchronize the local setup with the remote
  c, crons                List the native Linx commands

Options:
  -c, --commands          List the native Linx commands
  -d, --dir               Print the absolute path to linx work directory
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

handle_commands() {
    cat "${LINX_INSTALLED_COMMANDS}"
}

handle_crons() {
    show_crons
}

show_crons() {
    if [[ ! -f "${CRON_JOBS_FILE}" && ! -s "${CRON_JOBS_FILE}" ]]; then
        echo "No cron jobs scheduled via linx."
        return 1
    fi
    cat "${CRON_JOBS_FILE}"
}

# @description Synchronize the local linx installation with the latest version from the remote
# @return 0 if the configuration was synchronized successfully; 1 otherwise
linx() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            s|sync)
                pull_setup
                return 0
                ;;
            c|cron)
                handle_crons "$@"
                return 0
                ;;
            -c|--commands)
                handle_commands "$@"
                return 0
                ;;
            -d|--dir)
                echo "${LINX_DIR}"
                return 0
                ;;
            -h|--help)
                echo "${USAGE}"
                return 0
                ;;
            -v|--version)
                echo "${VERSION}"
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