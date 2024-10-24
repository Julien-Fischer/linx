#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Source linx
if [ -f ~/.linx_lib.sh ]; then
    source "${HOME}"/.linx_lib.sh
fi

project_name="${PROJECT}"

echo "this will uninstall ${project_name}."
confirm "Uninstallation" "Proceed?" --abort

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

if confirm "Removal" "Remove Terminator configuration files?"; then
    sudo rm ~/.config/terminator/*
else
    echo "Configuration files preserved"
fi

# Uninstall linx-native commands
for command in "${COMMANDS[@]}"; do
    uninstall_command "${command}"
done

del "${CURRENT_THEME_FILE}"

# Remove linx core
del ~/linx.sh
del ~/.linx_lib.sh


echo "${project_name} was successfully uninstalled."