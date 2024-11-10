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

##############################################################
# Doc
##############################################################

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

CRON_USAGE=$(cat <<EOF
  Usage: linx cron [OPTIONS]

  List the cron jobs installed via linx.

  Options:
    -c, --clear           Remove all cron jobs installed via linx
    -d, --delete          Delete a specific cron jobs installed via linx
    -h, --help            Show this message and exit
EOF
)

##############################################################
# Process
##############################################################

handle_commands() {
    cat "${LINX_INSTALLED_COMMANDS}"
}

handle_crons() {
    local args=""
    local delete_all=false
    local delete_one=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                args+=' --yes'
                ;;
            -c|--clear)
                delete_all=true
                ;;
            -d|--delete)
                delete_one=true
                ;;
            -h|--help)
                echo "${CRON_USAGE}"
                return 0
                ;;
            *)
                err "Invalid parameter ${1}"
                echo "${CRON_USAGE}"
                return 1
                ;;
        esac
        shift
    done
    if $delete_all; then
        # shellcheck disable=SC2086
        delete_all_jobs $args
        return 0
    fi
    if $delete_one; then
        delete_job
        return 0
    fi
    read_crons
}

delete_job() {
    echo 'Type the index of the job you wish to delete:'
    mapfile -t linx_jobs < "${CRON_JOBS_FILE}"
    print_array linx_jobs
    local index=$(prompt "Which job do you wish to delete?")
    remove_job $((index-1))
}

delete_all_jobs() {
    local auto_approve=false
    if [[ "${1}" == '-y' || "${1}" == '--yes' ]]; then
        auto_approve=true
    fi
    echo "This will clear all cron jobs scheduled via linx."
    ! $auto_approve && confirm "Deletion" "Proceed?" --abort
    mapfile -t linx_jobs < "${CRON_JOBS_FILE}"
    for ((i=0; i<${#linx_jobs[@]}; i++)); do
        remove_job $i
    done
}

remove_job() {
    local index="${1}"
    local job_to_remove="${linx_jobs[index]}"
    if ! remove_cron_entry "${job_to_remove}"; then
        err "Could not remove ${job_to_remove} from the crontab"
        return 1
    fi
    if ! remove_first_line_containing "${CRON_JOBS_FILE}" "${job_to_remove}"; then
        err "Could not remove ${job_to_remove} from linx files"
        return 1
    fi
    echo "${job_to_remove} has been removed."
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

read_crons() {
    if [[ ! -f "${CRON_JOBS_FILE}" || ! -s "${CRON_JOBS_FILE}" ]]; then
        echo "No cron jobs scheduled via linx."
        return 1
    fi
    cat "${CRON_JOBS_FILE}"
}

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