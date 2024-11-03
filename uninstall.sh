#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Source linx
if [ -f ~/.linx_lib.sh ]; then
    source "${HOME}"/.linx_lib.sh
fi

##############################################################
# Parameters
##############################################################

auto_approve=1

##############################################################
# Constants
##############################################################

project_name="${PROJECT}"

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
        del /usr/local/bin/"${command}"
    fi
}

uninstall_commands() {
    mapfile -t COMMANDS < <(cat "${LINX_INSTALLED_COMMANDS}")
    for command in "${COMMANDS[@]}"; do
        uninstall_command "${command}"
    done
    del "${LINX_INSTALLED_COMMANDS}"
}

uninstall_linx() {
    echo "this will uninstall ${project_name}."
    [[ $auto_approve -ne 0 ]] && confirm "Uninstallation" "Proceed?" --abort

    if [[ $auto_approve -eq 0 ]] || confirm "Removal" "Remove Terminator configuration files?"; then
        sudo rm ~/.config/terminator/*
    else
        echo "Configuration files preserved"
    fi

    uninstall_commands

    del "${CURRENT_THEME_FILE}"

    # Remove linx core
    del ~/linx.sh
    del ~/.linx_lib.sh

    echo "${project_name} was successfully uninstalled."
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