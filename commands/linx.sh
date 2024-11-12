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
  c, cron                 List the native Linx commands

Options:
  -c, --commands          List the native Linx commands
  -d, --dir               Print the absolute path to linx work directory
  -h, --help              Show this message and exit
  -v, --version           Show Linx version and exit
EOF
)

SYNC_USAGE=$(cat <<EOF
  Usage: linx sync [OPTIONS]

  Synchronize the local configuration with the remote.

  Options:
    -b, --backup          Create a timestamped backup as a zip file before synchronizing the local version of linx
                          This is equivalent of executing linx b && linx s
    -h, --help            Show this message and exit
EOF
)

BACKUP_USAGE=$(cat <<EOF
  Usage: linx sync [OPTIONS]

  Create a timestamped backup as a zip file before synchronizing the local version of linx.

  Options:
    -h, --help            Show this message and exit
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

backup_local_config() {
    set -e  # Exit immediately if a command exits with a non-zero status
    trap 'err "Backup failed."; return 1' ERR

    local filename="linx_$(timestamp -s - _ -)"
    local absolute_path="${LINX_BACKUPS_DIR}/${filename}"

    local temp_dir=$(mktemp -d)
    local command_dir_backup="${temp_dir}/commands"

    echo "${VERSION}" > "${temp_dir}/VERSION"
    cp -r "${LINX_DIR}" "${temp_dir}/" > /dev/null
    cp -r "${TERMINATOR_DIR}" "${temp_dir}/" > /dev/null
    mkdir -p "${command_dir_backup}" > /dev/null

    while IFS= read -r cmd; do
        if [[ -n "${cmd}" ]]; then
            local command_file="${COMMANDS_DIR}/${cmd}"
            if [[ -f "${command_file}" ]]; then
                cp "${command_file}" "${command_dir_backup}/" > /dev/null
            else
                echo "Warning: ${cmd} not found in ${COMMANDS_DIR}"
            fi
        fi
    done < <(read_commands)

    (cd "${temp_dir}" && sudo zip -r "${absolute_path}" . > /dev/null)

    rm -rf "${temp_dir}" > /dev/null

    echo -e "Backed up local configuration at $(color "${absolute_path}" "${GREEN_BOLD}")"

    trap - ERR  # Reset the error trap
    set +e  # Reset the exit-on-error option
}


handle_sync() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--backup)
                backup_local_config "$@"
                ;;
            -h|--help)
                echo "${SYNC_USAGE}"
                return 0
                ;;
            *)
                err "Invalid parameter ${1}"
                echo "${SYNC_USAGE}"
                return 1
                ;;
        esac
        shift
    done

    pull_setup
    return $?
}

handle_commands() {
    read_commands
}

read_commands() {
    cat "${LINX_INSTALLED_COMMANDS}"
}

handle_backup() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "${SYNC_USAGE}"
                return 0
                ;;
            *)
                err "Invalid parameter ${1}"
                echo "${BACKUP_USAGE}"
                return 1
                ;;
        esac
    done

    backup_local_config
    return $?
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
    return $?
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
    remove_cron_entry "${job_to_remove}" --quiet
    remove_first_line_containing "${CRON_JOBS_FILE}" "${job_to_remove}"
    echo "${job_to_remove} has been removed."
}

remove_cron_entry() {
    local quiet=false
    local substring="$1"
    if [[ "${2}" == "-q" || "${2}" == "--quiet" ]]; then
        quiet=true
    fi
    if crontab -l | grep -q "$substring"; then
        crontab -l | grep -v "$substring" | crontab -
        return 0
    else
        ! $quiet && err "No cron entry found containing '${substring}'."
        return 1
    fi
}

read_crons() {
    if [[ ! -f "${CRON_JOBS_FILE}" || ! -s "${CRON_JOBS_FILE}" ]]; then
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
            c|cron)
                shift
                handle_crons "$@"
                return 0
                ;;
            b|backup)
                shift
                handle_backup "$@"
                return 0
                ;;
            s|sync)
                shift
                handle_sync "$@"
                return 0
                ;;
            -c|--commands)
                shift
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