#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Source linx
if [ -f "${HOME}"/linx/.linx_lib.sh ]; then
    source "${HOME}"/linx/.linx_lib.sh
else
    echo "linx was not found on this system."
    exit 1
fi

##############################################################
# Parameters
##############################################################

auto_approve=false

##############################################################
# Uninstallation process
##############################################################

try_removing() {
    local path="${1}"
    if del "${path}"; then
        echo "Removed ${path}"
    else
        echo "${path} is not installed. Skipped." >&2
    fi
}

uninstall_command() {
    local command="${1}"
    if installed "${command}" -q; then
        del "${LINX_COMMANDS_DIR}/${command}" -q
    fi
}

uninstall_commands() {
    if [[ ! -f "${LINX_INSTALLED_COMMANDS}" ]]; then
        return 0
    fi
    mapfile -t COMMANDS < "${LINX_INSTALLED_COMMANDS}"
    echo "Uninstalling linx commands..."
    for command in "${COMMANDS[@]}"; do
        command=$(echo "$command" | xargs)
        if [[ -n "${command}" ]] && uninstall_command "${command}"; then
            echo "  ${command}"
        fi
    done
    echo "linx commands uninstalled."
    rm "${LINX_INSTALLED_COMMANDS}"
}

uninstall_cron_jobs() {
    if [[ ! -f "${LINX_CRON_FILE}" ]]; then
        return 0
    fi
    local linx_cron_jobs job_count
    linx_cron_jobs=$(linx cron)
    job_count=$(echo "$linx_cron_jobs" | grep -c .)
    if [[ $job_count -gt 0 ]]; then
        echo "${job_count} cron jobs were installed using linx."
        if $auto_approve || confirm "Removal" "Remove them?"; then
            linx cron --clear -y
        fi
    fi
}

uninstall_terminator_config() {
    if ($auto_approve || \
       confirm "Removal" "Remove Terminator configuration files?") && \
       [[ -n $(ls -A "${HOME}/.config/terminator") ]]; then
        sudo rm "${HOME}"/.config/terminator/*
    else
        echo "Configuration files preserved"
    fi
    if [[ -f "${TERMINATOR_CURRENT_THEME_FILE}" ]]; then
        rm "${TERMINATOR_CURRENT_THEME_FILE}"
    fi
}

uninstall_linx() {
    echo "this will uninstall linx."
    ! $auto_approve && confirm "Uninstallation" "Proceed?" --abort
    uninstall_terminator_config
    uninstall_cron_jobs
    uninstall_commands
    if [[ -d "${LINX_DIR}" ]]; then
        del "${LINX_DIR}"
    fi
    echo "linx was successfully uninstalled."
}

uninstall() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                auto_approve=true
                shift
                ;;
            *)
                echo "Usage: ./uninstall.sh [-y]"
                return 1
                ;;
        esac
    done
    uninstall_linx "$@"
}

uninstall "$@"
