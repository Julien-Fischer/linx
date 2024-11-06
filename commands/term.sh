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
# Documentation
##############################################################

USAGE=$(cat <<EOF
Usage: term [OPTIONS]

Options:
  p, profiles [OPTIONS]   Lists the available profiles, or switch to the specified profile
  l, layouts [OPTIONS]   Lists the available layouts, or switch to the specified layout

Description:
  Manages Terminator configuration directly in the command-line

Example:
  # themes
  term profiles
  term profiles --set contrast
  term p -s contrast
  # layouts
  term layouts
  term layouts --get grid
  term l -g grid
EOF
)

fail() {
    echo "Unsupported parameter ${1}"
    echo "${USAGE}"
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

##############################################################
# Profiles
##############################################################

set_profile() {
    local profile_name="${1}"
    if [[ -z "${profile_name}" ]]; then
        echo "Profile name is required"
        echo ""
        echo "${USAGE}"
        return 1
    fi
    local styles=$(print_profile "${profile_name}")
    if [[ -z "${styles}" ]]; then
        echo "${profile_name} profile not found."
        return 1
    fi

    local temp_file=$(mktemp)
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
    if [[ -z "${profile_name}" ]]; then
        echo "Profile name is required"
        echo ""
        echo "${USAGE}"
        return 1
    fi
    if [[ ! -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        echo "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi
    local reading_profiles=1
    local reading_target_profile=1
    local styles=()
    local style_string=""
    while IFS= read -r line; do
        if [[ "${line}" == *"[profiles]"* ]]; then
            reading_profiles=0
            continue
        fi
        if [[ $reading_profiles -eq 0 && "${line}" =~ \[?\[[^\]]+\]\]? ]]; then
            if [[ "${line}" =~ [[:space:]]*\[${profile_name}\][[:space:]]* ]]; then
                reading_target_profile=0
            elif [[ $reading_target_profile -eq 0 ]]; then
                reading_target_profile=1
            fi
            continue
        fi
        if [[ $reading_target_profile -eq 0  ]]; then
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
        echo "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi
    local reading_profiles=1
    local profiles=()
    while IFS= read -r line; do
        if is_comment "${line}"; then
            continue;
        fi
        if [[ "${line}" == *"[profiles]"* ]]; then
            reading_profiles=0
            continue
        fi
        if [[ "${line}" =~ ^\[[^\]]+\]$ && "${line}" != *"[profiles]"* ]]; then
            reading_profiles=1
        fi
        if [[ $reading_profiles -eq 0 && "${line}" =~ \[\[([^\]]+)\]\] ]]; then
            profiles+=("${BASH_REMATCH[1]}")
        fi
    done < "${TERMINATOR_CONFIG_FILE}"
    echo "${#profiles[@]} available profiles:"
    local current_layout=
    if [[ -f "${CURRENT_THEME_FILE}" ]]; then
        current_layout=$(cat "${CURRENT_THEME_FILE}")
    fi
    for profile in "${profiles[@]}"; do
        if [[ -n "${current_layout}" && "${profile}" == "${current_layout}" ]]; then
            echo -e "> $(color "${profile}")"
        else
            echo "- ${profile}"
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
    local profile_name="${1}"
    if [[ -z "${profile_name}" ]]; then
        list_profiles
        return 0
    fi
    if set_profile "${profile_name}"; then
        echo "Switched to ${profile_name} profile. Restart Terminator to apply the theme."
        return 0
    fi
    echo -e "$(color "E:") Could not switch to ${profile_name} profile."
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
    if [[ -z "${layout_name}" ]]; then
        list_layouts
        return 0
    fi
    if set_layout "$@"; then
        echo "Switched to ${layout_name} layout. Restart Terminator to apply changes."
        return 0
    fi
    echo -e "$(color "E:") Could not switch to ${layout_name} layout."
    return 1
}

set_layout() {
    local layout_name="${1}"
    if [[ -z "${layout_name}" ]]; then
        echo "Profile name is required"
        echo ""
        echo "${USAGE}"
        return 1
    fi
    local styles=$(print_layout "${layout_name}")
    if [[ -z "${styles}" ]]; then
        echo "${layout_name} layout not found."
        return 1
    fi

    local temp_file=$(mktemp)
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
            ( "${line}" =~ ^[[:space:]]+[a-zA-Z_]+[[:space:]]*= ||
              "${line}" =~ ^[[:space:]]*\[{3}[[:space:]]* )
         ]]; then
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
        echo "Profile name is required"
        echo ""
        echo "${USAGE}"
        return 1
    fi
    if [[ ! -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        echo "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi
    local reading_layouts=1
    local reading_target_layout=1
    local styles=()
    local style_string=""
    while IFS= read -r line; do
        if [[ "${line}" == *"[layouts]"* ]]; then
            reading_layouts=0
            continue
        fi
        if [[ $reading_layouts -eq 0 && "${line}" =~ ^[[:space:]]*\[\[([^]]+)\]\][[:space:]]*$ ]]; then
            if [[ "${BASH_REMATCH[1]}" == "${layout_name}" ]]; then
                reading_target_layout=0
            elif [[ $reading_target_layout -eq 0 ]]; then
                break
            fi
            continue
        fi
        if [[ $reading_target_layout -eq 0 ]]; then
            # Check if the line is the start of a new section
            if [[ "${line}" =~ ^\[.*\]$ ]]; then
                break
            fi
            styles+=("${line}")
        fi
    done < "${TERMINATOR_CONFIG_FILE}"
    if [[ "${#styles[@]}" -gt 0 ]]; then
        for i in "${!styles[@]}"; do
            if [ $i -eq $((${#styles[@]} - 1)) ]; then
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
        echo "Configuration file not found at ${TERMINATOR_CONFIG_FILE}"
        return 1
    fi
    local reading_layouts=1
    local layouts=()
    while IFS= read -r line; do
        if is_comment "${line}"; then
            continue;
        fi
        if [[ "${line}" == *"[layouts]"* ]]; then
            reading_layouts=0
            continue
        fi
        if [[ $reading_layouts -eq 0 && "${line}" =~ ^\[[^\]]+\]$ && "${line}" != *"[layouts]"* ]]; then
            reading_layouts=1
            continue
        fi
    if [[ $reading_layouts -eq 0 && "${line}" =~ ^[[:space:]]*\[\[([^]]+)\]\][[:space:]]*$ ]]; then
        layouts+=("${BASH_REMATCH[1]}")
    fi
    done < "${TERMINATOR_CONFIG_FILE}"

    echo "${#layouts[@]} available layouts:"
    local current_layout=
    if [[ -f "${CURRENT_LAYOUT_FILE}" ]]; then
        current_layout=$(cat "${CURRENT_LAYOUT_FILE}")
    fi
    for layout in "${layouts[@]}"; do
        if [[ -n "${current_layout}" && "${layout}" == "${current_layout}" ]]; then
            echo -e "> $(color "${layout}")"
        else
            echo "- ${layout}"
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
            *)
                fail "${1}"
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
            *)
                fail "${1}"
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
                echo "${USAGE}"
                return 0
                ;;
            *)
                fail "${1}"
                ;;
        esac
    done
    echo "${USAGE}"
    return 1
}

main "$@"