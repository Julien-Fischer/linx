#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Source linx
if [ -f "${LINX_DIR}"/.linx_lib.sh ]; then
    source "${LINX_DIR}"/.linx_lib.sh
else
    echo "linx was not found on this system."
    exit 1
fi

##############################################################
# Parameters
##############################################################

auto_approve=1

##############################################################
# Uninstallation process
##############################################################

try_removing() {
    local path="${1}"
    if del "${path}"; then
        echo "Removed ${path}"
    else
        echo "${path} is not installed. Skipped."
    fi
}

uninstall_command() {
    local command="${1}"
    if installed "${command}" -q; then
        del /usr/local/bin/"${command}" -q
    fi
}

uninstall_commands() {
    if [[ ! -f "${LINX_INSTALLED_COMMANDS}" ]]; then
        return 0
    fi
    mapfile -t COMMANDS < "${LINX_INSTALLED_COMMANDS}"
    for command in "${COMMANDS[@]}"; do
        command=$(echo "$command" | xargs)
        if [[ -n "${command}" ]] && uninstall_command "${command}"; then
            echo "Uninstalled ${command} command"
        fi
    done
    rm "${LINX_INSTALLED_COMMANDS}"
}

uninstall_terminator_config() {
    if ([[ $auto_approve -eq 0 ]] || \
       confirm "Removal" "Remove Terminator configuration files?") && \
       [[ -n $(ls -A ~/.config/terminator) ]]; then
        sudo rm ~/.config/terminator/*
    else
        echo "Configuration files preserved"
    fi
    if [[ -f "${CURRENT_THEME_FILE}" ]]; then
        rm "${CURRENT_THEME_FILE}"
    fi
}

uninstall_linx() {
    echo "this will uninstall linx."
    [[ $auto_approve -ne 0 ]] && confirm "Uninstallation" "Proceed?" --abort
    uninstall_terminator_config
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
                auto_approve=0
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