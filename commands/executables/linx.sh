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
# Process
##############################################################

print_info() {
    echo "linx $(linx --version)"
    echo "Author: Julien Fischer <julien.fischer@agiledeveloper.net>"
    echo "Repository: ${LINX_REPOSITORY}"
    echo "For help, use linx --help or linx -h"
}

backup_local_config() {
    set -e  # Exit immediately if a command exits with a non-zero status
    trap 'err "Backup failed."; return 1' ERR

    local filename temp_dir
    filename="linx_$(timestamp -s - _ -)"
    temp_dir=$(mktemp -d)
    local absolute_path="${LINX_BACKUPS_DIR}/${filename}"
    local command_dir_backup="${temp_dir}/commands"

    echo "${LINX_VERSION}" > "${temp_dir}/VERSION"
    cp -r "${LINX_DIR}" "${temp_dir}/" > /dev/null
    cp -r "${TERMINATOR_DIR}" "${temp_dir}/" > /dev/null
    mkdir -p "${command_dir_backup}" > /dev/null

    while IFS= read -r cmd; do
        if [[ -n "${cmd}" ]]; then
            local command_file="${LINX_COMMANDS_DIR}/${cmd}"
            if [[ -f "${command_file}" ]]; then
                cp "${command_file}" "${command_dir_backup}/" > /dev/null
            else
                echo "Warning: ${cmd} not found in ${LINX_COMMANDS_DIR}"
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
    require_sudo "synchronize your local ${LINX_PROJECT} installation with the remote."
    local branch_name
    if [[ -n "${1}" && "${1}" != -* ]]; then
        branch_name="${1}"
        shift
    fi
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--backup)
                backup_local_config "$@"
                ;;
            -h|--help)
                get_help "linx-sync"
                return 0
                ;;
            *)
                err "Invalid parameter ${1}"
                get_help "linx-sync"
                return 1
                ;;
        esac
        shift
    done

    pull_setup "${branch_name}"
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
                get_help "linx-backup"
                return 0
                ;;
            *)
                err "Invalid parameter ${1}"
                get_help "linx-backup"
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
                get_help "linx-cron"
                return 0
                ;;
            *)
                err "Invalid parameter ${1}"
                get_help "linx-cron"
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
    mapfile -t linx_jobs < "${LINX_CRON_JOBS_FILE}"
    print_array linx_jobs
    local index
    index=$(prompt "Which job do you wish to delete?")
    remove_job $((index-1))
}

delete_all_jobs() {
    local auto_approve=false
    if [[ "${1}" == '-y' || "${1}" == '--yes' ]]; then
        auto_approve=true
    fi
    echo "This will clear all cron jobs scheduled via linx."
    ! $auto_approve && confirm "Deletion" "Proceed?" --abort
    mapfile -t linx_jobs < "${LINX_CRON_JOBS_FILE}"
    for ((i=0; i<${#linx_jobs[@]}; i++)); do
        remove_job $i
    done
}

remove_job() {
    local index="${1}"
    local job_to_remove="${linx_jobs[index]}"
    remove_cron_entry "${job_to_remove}" --quiet
    remove_first_line_containing "${LINX_CRON_JOBS_FILE}" "${job_to_remove}"
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
    if [[ ! -f "${LINX_CRON_JOBS_FILE}" ]]; then
        err "Could not read linx cron file at ${LINX_CRON_JOBS_FILE}"
        return 1
    fi
    cat "${LINX_CRON_JOBS_FILE}"
}

pull_setup() {
    local branch_name="${1}"
    if install_core "${branch_name}"; then
        echo -e "$(color "${LINX_PROJECT}: successfully synced [$(linx -v)]" "${GREEN_BOLD}")"
    else
        echo -e "$(color "${LINX_PROJECT}: failed to sync" "${RED_BOLD}")"
        return 1
    fi
}

handle_config() {
  if [[ -f "${LINX_CONFIG_FILE}" ]]; then
      vim "${LINX_CONFIG_FILE}"
  else
      err "Could not find linx config file at ${LINX_CONFIG_FILE}"
      echo "Generating a new one..."
      echo '# linx configuration file' > "${LINX_CONFIG_FILE}"
      vim "${LINX_CONFIG_FILE}"
  fi
}


# @description Synchronize the local linx installation with the latest version from the remote
# @return 0 if the configuration was synchronized successfully; 1 otherwise
linx() {
    case $1 in
        config)
            handle_config
            ;;
        c|cron)
            shift
            handle_crons "$@"
            ;;
        b|backup)
            shift
            handle_backup "$@"
            ;;
        s|sync)
            shift
            handle_sync "$@"
            ;;
        -c|--commands)
            shift
            handle_commands "$@"
            ;;
        -d|--dir)
            echo "${LINX_DIR}"
            ;;
        -h|--help)
            get_help "linx"
            ;;
        -i|--info)
            print_info
            ;;
        -v|--version)
            echo "${LINX_VERSION}"
            ;;
        *)
            err "Invalid parameter ${1}"
            get_help "linx"
            return 1
            ;;
    esac
}

linx "$@"
