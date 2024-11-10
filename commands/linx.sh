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
    while [[ $# -gt 0 ]]; do
        echo "evaluating... '${1}'"
        case $1 in
            -d|--delete)
                echo 'Type the index of the job you wish to delete:'
                mapfile -t linx_jobs < "${CRON_JOBS_FILE}"
                read_array linx_jobs
                local index=$(prompt "Which job do you wish to delete?")
                local job_to_remove="${linx_jobs[((index-1))]}"
                remove_cron_entry "${job_to_remove}"
                remove_first_line_containing "${CRON_JOBS_FILE}" "${job_to_remove}"
                echo "${job_to_remove} has been removed."
                return 0
                ;;
            *)
                err "Invalid parameter ${1}"
                echo "${CRON_USAGE}"
                return 1
                ;;
        esac
    done
    read_crons
}

remove_cron_entry() {
    local substring="$1"
    if crontab -l | grep -q "$substring"; then
        crontab -l | grep -v "$substring" | crontab -
        return 0
    else
        err "No cron entry found containing '${substring}'."
        return 1
    fi
}

# @description Remove the first line matching the specified substring
# @param $1 The file to process
# @param $2 The substring to match
remove_first_line_containing() {
    local file="$1"
    local substring="$2"

    # Check if the file exists
    if [[ ! -f "$file" ]]; then
        err "File '$file' does not exist."
        return 1
    fi

    # Check if the substring exists in the file
    if grep -q "$substring" "$file"; then
        # Create a temporary file
        local temp_file=$(mktemp)

        # Remove the line containing the substring and save to temp file
        grep -v "$substring" "$file" > "$temp_file"

        # Replace the original file with the modified content
        mv "$temp_file" "$file"
        return 0
    else
        err "No entry found containing '$substring' in file '$file'."
        return 1
    fi
}


read_crons() {
    if [[ ! -f "${CRON_JOBS_FILE}" && ! -s "${CRON_JOBS_FILE}" ]]; then
        echo "No cron jobs scheduled via linx."
        return 1
    fi
    cat "${CRON_JOBS_FILE}"
}

read_array() {
    # Use nameref to reference the passed array
    local -n array_ref="$1"
    local line_number=1

    for line in "${array_ref[@]}"; do
        printf "[%d] %s\n" "$line_number" "$line"
        ((line_number++))
    done
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
                shift
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