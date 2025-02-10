#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
else
    echo "E: Could not source ${LINX_DIR}/.linx_lib.sh"
fi
source "${HOME}"/.bashrc

##############################################################
# Constants
##############################################################

SHELL="bash"

##############################################################
# Documentation
##############################################################

fail() {
    local suffix=''
    if [[ -n "${2}" ]]; then
        suffix="${2}"
    fi
    err "Unsupported parameter ${1}"
    get_help "term-${suffix}"
    exit 1
}

##############################################################
# Utils
##############################################################

is_comment() {
    local line="${1}"
    if [[ "${line}" =~ ^[[:space:]]*# ]]; then
        return 0
    else
        return 1
    fi
}

read_command() {
    get_linx_property "terminator.override.command" -q --raw
}

##############################################################
# Profiles
##############################################################

set_profile() {
    local profile_name="${1}"
    if [[ -z "${profile_name}" ]]; then
        err "Profile name is required"
        err ""
        get_help "term-profiles"
        return 1
    fi
    local styles temp_file
    styles=$(print_profile "${profile_name}")
    if [[ -z "${styles}" ]]; then
        echo "${profile_name} profile not found."
        return 1
    fi

    temp_file=$(mktemp)
    local reading_target_profile=false
    local reading_profiles=false

    while IFS= read -r line; do
        if is_comment "${line}"; then
            continue;
        fi
        if [[ "${line}" == *"[profiles]"* ]]; then
            reading_profiles=true
        elif $reading_profiles && [[ "${line}" =~ ^\[[^]]*\]$ && "${line}" != *"[profiles]"* ]]; then
            reading_profiles=false
            reading_target_profile=false
        fi

        if $reading_profiles && [[ "${line}" == *"[[default]]"* ]]; then
            reading_target_profile=true
            echo "${line}" >> "${temp_file}"
            echo "${styles}" >> "${temp_file}"

            local command
            command="$(read_command)"
            if [[ -n "${command}" ]]; then
                {
                  echo '    exit_action = hold'
                  echo '    use_custom_command = True'
                  echo "    custom_command = '${command}; ${SHELL}'"
                } >> "${temp_file}"
            fi
        elif $reading_target_profile && [[ "${line}" =~ ^[[:space:]]*\[\[ ]]; then
            reading_target_profile=false
            echo "${line}" >> "${temp_file}"
        elif $reading_target_profile && [[ "${line}" =~ ^[[:space:]]+[a-zA-Z_]+[[:space:]]*= ]]; then
            continue
        else
            echo "${line}" >> "${temp_file}"
        fi
    done < "${TERMINATOR_CONFIG_FILE}"

    cp "${TERMINATOR_CONFIG_FILE}" "${TERMINATOR_CONFIG_FILE}.bak"
    sudo mv "${temp_file}" "${TERMINATOR_CONFIG_FILE}"
    echo "${profile_name}" > "${CURRENT_THEME_FILE}"
}

print_profile() {
    local profile_name="${1}"
    shift
    if [[ -z "${profile_name}" ]]; then
        err "Profile name is required"
        err ""
        get_help "term-profiles"
        return 1
    fi
    if [[ ! -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        err "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi
    local reading_profiles=false
    local reading_target_profile=false
    local styles=()
    local style_string=""
    while IFS= read -r line; do
        if [[ "${line}" == *"[profiles]"* ]]; then
            reading_profiles=true
            continue
        fi
        if $reading_profiles && [[ "${line}" =~ \[?\[[^\]]+\]\]? ]]; then
            if [[ "${line}" =~ [[:space:]]*\[${profile_name}\][[:space:]]* ]]; then
                reading_target_profile=true
            elif $reading_target_profile; then
                reading_target_profile=false
            fi
            continue
        fi
        if $reading_target_profile; then
            styles+=("${line}")
        fi
    done < "${TERMINATOR_CONFIG_FILE}"
    if [[ "${#styles[@]}" -gt 0 ]]; then
        for i in "${!styles[@]}"; do
            if [ $i -eq $((${#styles[@]} - 1)) ]; then
                style_string+="${styles[i]}"
            else
                style_string+="${styles[i]}\n"
            fi
        done
        echo -e "${style_string}"
    else
        return 1
    fi
}

# @description Although this function could be invoked directly, it is usually executed via the profiles function
# @example
#  # The following function calls are strictly equivalent:
#  profiles
#  print_profile
list_profiles() {
    if [[ ! -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        err "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi

    local raw=false
    if [[ "${1}" == --list ]]; then
        raw=true
    fi
    local reading_profiles=false
    local profiles=()
    local current_profile

    while IFS= read -r line; do
        if is_comment "${line}"; then
            continue;
        fi
        if [[ "${line}" == *"[profiles]"* ]]; then
            reading_profiles=true
            continue
        fi
        if [[ "${line}" =~ ^\[[^\]]+\]$ && "${line}" != *"[profiles]"* ]]; then
            reading_profiles=false
        fi
        if $reading_profiles && [[ "${line}" =~ \[\[([^\]]+)\]\] ]]; then
            profiles+=("${BASH_REMATCH[1]}")
        fi
    done < "${TERMINATOR_CONFIG_FILE}"

    if ! $raw; then
        echo "${#profiles[@]} available profiles:"
    fi
    if [[ -f "${CURRENT_THEME_FILE}" ]]; then
        current_profile=$(cat "${CURRENT_THEME_FILE}")
    fi
    for profile in "${profiles[@]}"; do
        if $raw; then
            echo "${profile}"
        else
            if [[ -n "${current_profile}" && "${profile}" == "${current_profile}" ]]; then
                echo -e "> $(color "${profile}")"
            else
                echo "- ${profile}"
            fi
        fi
    done
}

# @description Switch to a specified Terminator profile. If no parameter is provided, list the available profiles
# @param $1  (optional) the name of the profile to switch to
# @example
#   # List available profiles
#   profiles
#   # Switch to the specified profile
#   profiles profile_name
profiles() {
    if [[ -z "${1}" || "${1}" == -* ]]; then
        list_profiles "$@"
        return 0
    fi
    local profile_name="${1}"
    if set_profile "${profile_name}"; then
        echo "Switched to ${profile_name} profile. Restart Terminator to apply the theme."
        return 0
    fi
    err "Could not switch to ${profile_name} profile."
    return 1
}

##############################################################
# Layouts
##############################################################

# @description Switch to a specified Terminator layout. If no parameter is provided, list the available layouts
# @param $1  (optional) the name of the layout to switch to
# @example
#   # List available layouts
#   layouts
#   # Switch to the specified layout
#   layouts layout_name
layouts() {
    local layout_name="${1}"
    if [[ -z "${layout_name}" || "${1}" == -* ]]; then
        list_layouts "$@"
        return 0
    fi
    if set_layout "$@"; then
        echo "Switched to ${layout_name} layout. Restart Terminator to apply changes."
        return 0
    fi
    err "Could not switch to ${layout_name} layout."
    return 1
}

set_layout() {
    local layout_name="${1}"
    if [[ -z "${layout_name}" ]]; then
        err "Profile name is required"
        err ""
        get_help "term-layouts"
        return 1
    fi
    local styles temp_file
    styles=$(print_layout "${layout_name}")
    if [[ -z "${styles}" ]]; then
        err "${layout_name} layout not found."
        return 1
    fi

    temp_file=$(mktemp)
    local reading_target_layout=false
    local reading_layouts=false

    while IFS= read -r line; do
        if is_comment "${line}"; then
            continue;
        fi
        if [[ "${line}" == *"[layouts]"* ]]; then
            reading_layouts=true
        elif $reading_layouts && [[ "${line}" =~ ^\[[^]]*\]$ && "${line}" != *"[layouts]"* ]]; then
            reading_layouts=false
            reading_target_layout=false
        fi
        if $reading_layouts && [[ "${line}" == *"[[default]]"* ]]; then
            reading_target_layout=true
            echo "${line}" >> "${temp_file}"
            echo "${styles}" >> "${temp_file}"
        elif $reading_target_layout && [[ "${line}" =~ ^[[:space:]]*\[\[[^\[] ]]; then
            reading_target_layout=false
            echo "${line}" >> "${temp_file}"
        elif $reading_target_layout && [[
                "${line}" =~ ^[[:space:]]+[a-zA-Z_]+[[:space:]]*= ||
                "${line}" =~ ^[[:space:]]*\[{3}[[:space:]]* ]]; then

#    elif $reading_target_layout && [[
#            ("${line}" =~ ^[[:space:]]+[a-zA-Z_]+[[:space:]]*= ||
#             "${line}" =~ ^[[:space:]]*\[{3}[[:space:]]*)
#         ]]; then
            continue
        else
            echo "${line}" >> "${temp_file}"
        fi
    done < "${TERMINATOR_CONFIG_FILE}"

    backup "${TERMINATOR_CONFIG_FILE}" -q
    sudo mv "$temp_file" "${TERMINATOR_CONFIG_FILE}"
    echo "${layout_name}" > "${CURRENT_LAYOUT_FILE}"
}

print_layout() {
    local layout_name="${1}"
    if [[ -z "${layout_name}" ]]; then
        err "Profile name is required"
        err ""
        get_help "term-layouts"
        return 1
    fi
    if [[ ! -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        err "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi
    local reading_layouts=false
    local reading_target_layout=false
    local styles=()
    local style_string=""
    while IFS= read -r line; do
        if [[ "${line}" == *"[layouts]"* ]]; then
            reading_layouts=true
            continue
        fi
        if $reading_layouts && [[ "${line}" =~ ^[[:space:]]*\[\[([^]]+)\]\][[:space:]]*$ ]]; then
            if [[ "${BASH_REMATCH[1]}" == "${layout_name}" ]]; then
                reading_target_layout=true
            elif $reading_target_layout; then
                break
            fi
            continue
        fi
        if $reading_target_layout; then
            # Check if the line is the start of a new section
            if [[ "${line}" =~ ^\[.*\]$ ]]; then
                break
            fi
            styles+=("${line}")
        fi
    done < "${TERMINATOR_CONFIG_FILE}"

    local global_command regex
    global_command=$(get_linx_property "terminator.global.command" -q --raw)
    regex="^[[:space:]]*command[[:space:]]*=[[:space:]]*.*"
    if [[ "${#styles[@]}" -gt 0 ]]; then
        for i in "${!styles[@]}"; do
            if [[ "${styles[i]}" =~ $regex ]]; then
                styles[i]+=" && ${global_command}; ${SHELL}"
            fi

            if [[ $i -eq $((${#styles[@]} - 1)) ]]; then
                style_string+="${styles[i]}"
            else
                style_string+="${styles[i]}"$'\n'
            fi
        done
        echo -e "${style_string}"
    else
        echo "Layout '${layout_name}' not found or has no associated styles."
        return 1
    fi
}

# @description Although this function could be invoked directly, it is usually executed via the layouts function
# @example
#  # The following function calls are strictly equivalent:
#  layouts
#  print_layout
list_layouts() {
    if [[ ! -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        err "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi

    local raw=false
    if [[ "${1}" == --list ]]; then
        raw=true
    fi
    local reading_layouts=false
    local layouts=()
    local current_layout

    while IFS= read -r line; do
        if is_comment "${line}"; then
            continue;
        fi
        if [[ "${line}" == *"[layouts]"* ]]; then
            reading_layouts=true
            continue
        fi
        if $reading_layouts && [[ "${line}" =~ ^\[[^\]]+\]$ && "${line}" != *"[layouts]"* ]]; then
            reading_layouts=false
            continue
        fi
    if $reading_layouts && [[ "${line}" =~ ^[[:space:]]*\[\[([^]]+)\]\][[:space:]]*$ ]]; then
        layouts+=("${BASH_REMATCH[1]}")
    fi
    done < "${TERMINATOR_CONFIG_FILE}"

    if ! $raw; then
        echo "${#layouts[@]} available layouts:"
    fi
    if [[ -f "${CURRENT_LAYOUT_FILE}" ]]; then
        current_layout=$(cat "${CURRENT_LAYOUT_FILE}")
    fi
    for layout in "${layouts[@]}"; do
        if $raw; then
            echo "${layout}"
        else
            if [[ -n "${current_layout}" && "${layout}" == "${current_layout}" ]]; then
                echo -e "> $(color "${layout}")"
            else
                echo "- ${layout}"
            fi
        fi
    done
}

##############################################################
# Arguments parser
##############################################################

handle_profiles() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -g|--get)
                print_profile "${2}"
                return 0
                ;;
            -s|--set)
                profiles "${2}"
                return 0
                ;;
            --list)
                profiles "$@"
                return 0
                ;;
            -h|--help)
                get_help "term-profiles"
                return 0
                ;;
            *)
                fail "${1}" "profiles"
                ;;
        esac
    done
    profiles
}

handle_layouts() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -g|--get)
                print_layout "${2}"
                return 0
                ;;
            -s|--set)
                layouts "${2}"
                return 0
                ;;
            --list)
                layouts "$@"
                return 0
                ;;
            -h|--help)
                get_help "term-layouts"
                return 0
                ;;
            *)
                fail "${1}" "layouts"
                ;;
        esac
    done
    layouts
}

main() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            p|profiles)
                shift
                handle_profiles "$@"
                return $?
                ;;
            l|layouts)
                shift
                handle_layouts "$@"
                return $?
                ;;
            -h|--help)
                get_help "term"
                return 0
                ;;
            *)
                fail "${1}"
                ;;
        esac
    done
    get_help "term"
    return 1
}

main "$@"
