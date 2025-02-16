#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

##############################################################
# Constants
##############################################################

export LINX_VERSION="1.0.0-alpha10"
export LINX_PROJECT="linx"
export LINX_DIR="${HOME}/${LINX_PROJECT}"
export LINX_HELP_DIR="${LINX_DIR}/help"
export LINX_CRON_DIR="${LINX_DIR}/cron"
export LINX_CRON_JOBS_FILE="${LINX_CRON_DIR}/installed.log"
export LINX_CRON_LOG_FILE="${LINX_CRON_DIR}/jobs.log"
export LINX_BACKUPS_DIR="/var/backups"
LINX_FUNC_FILE_NAME="${LINX_PROJECT}.sh"
LINX_LIB_FILE_NAME=".${LINX_PROJECT}_lib.sh"
LINX_GITHUB_ACCOUNT="https://github.com/Julien-Fischer"
LINX_REPOSITORY="${LINX_GITHUB_ACCOUNT}/${LINX_PROJECT}.git"
LINX_COMMANDS_DIR="/usr/local/bin"
LINX_INSTALLED_COMMANDS="${LINX_DIR}/installed_commands"
LINX_MKF_DIR="${LINX_DIR}/mkf"
LINX_CONFIG_FILE="${LINX_DIR}/config.properties"
LINX_ANONYMIZE_FILE="${LINX_DIR}/anonymize.properties"
MKF_CONFIG_FILE="${LINX_MKF_DIR}/config"
MKF_TEMPLATE_DIR="${LINX_MKF_DIR}/templates"
DOCKER_CONFIG_DIR="${HOME}/docker_config"
DOCKER_KEEP_CONTAINERS_FILE="${DOCKER_CONFIG_DIR}/keep_containers"
DOCKER_KEEP_IMAGES_FILE="${DOCKER_CONFIG_DIR}/keep_images"
TERMINATOR_DIR="${HOME}/.config/terminator"
TERMINATOR_CONFIG_FILE="${TERMINATOR_DIR}/config"
TERMINATOR_CURRENT_THEME_FILE="${TERMINATOR_DIR}/current.profile"
TERMINATOR_CURRENT_LAYOUT_FILE="${TERMINATOR_DIR}/current.layout"
TERMINATOR_THEME_POLICY_FILE="${TERMINATOR_DIR}/theme_policy"
TERMINATOR_LOCAL_CONFIG_DIR="config/terminator"
TERMINATOR_THEMES_PROJECT="terminator_themes"
TERMINATOR_THEMES_REPOSITORY="${LINX_GITHUB_ACCOUNT}/${TERMINATOR_THEMES_PROJECT}.git"
TERMINATOR_DEFAULT_THEME_NATIVE="contrast"
TERMINATOR_DEFAULT_THEME_THIRD_PARTY="night_owl"
TERMINATOR_THIRD_PARTY_ENABLED_KEY="third_party_themes_enabled"
TERMINATOR_BACKUPS_CAPACITY=30
# shellcheck disable=SC2034
LINX_OUTPUT_SEPARATOR="________________________________________________________________________________"
LINX_SPINNER_PID=""

trap 'linx_spinner_stop' EXIT

########################################################################
# Constants
########################################################################

# Basic ANSI colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export GRAY='\033[0;90m'
# Bold ANSI colors
export RED_BOLD='\033[1;31m'
export GREEN_BOLD='\033[1;32m'
export YELLOW_BOLD='\033[1;33m'
export BLUE_BOLD='\033[1;34m'
export MAGENTA_BOLD='\033[1;35m'
export CYAN_BOLD='\033[1;36m'
export NC='\033[0m'

##############################################################
# Parameters
##############################################################

auto_approve=false
fresh_install=false

##############################################################
# Utils
##############################################################

# @description Declusters command-line arguments by separating clustered short options
#              into individual options while preserving other arguments and their order.
# @param $@ All command-line arguments passed to the function
# @example
#   decluster -abcd
#   # Output: -a -b -c -d
#   decluster param1 param2 -abcd
#   # Output: param1 param2 -a -b -c -d
#   decluster -abcd param1 param2 -xyz --long-option
#   # Output: -a -b -c -d param1 param2 -x -y -z --long-option
#   decluster --long-option -abcd param1 param2 -xyz
#   # Output: --long-option -a -b -c -d param1 param2 -x -y -z
decluster() {
    declare -a args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -[a-zA-Z]*)
                for (( i=1; i<${#1}; i++ )); do
                    args+=("-${1:i:1}")
                done
                ;;
            *)
                if [[ $1 == *[[:space:]]* ]]; then
                    args+=("$1")
                else
                    args+=("$1")
                fi
                ;;
        esac
        shift
    done
    # Use a special delimiter to separate arguments
    (IFS=$'\x1E'; echo "${args[*]}")
}

# @description Create a cron job from the specified expression and command only if it does not
#              exist yet
# @param $1 A cron expression
# @param $2 The command or script to schedule
# @flag -v, --verbose Log standard output for debugging
# @flag -q, --quiet Mute all outputs
# @example
#   add_cron '* * * * *' my_command
#   add_cron '* * * * *' my_command -v
add_cron() {
    local cron_expr="${1}"
    local command="${2}"
    local quiet=false
    local verbose=false
    local custom_params=''

    shift 2

    while [[ $# -gt 0 ]]; do
        case $1 in
            -q|--quiet)
                quiet=true
                ;;
            -v|--verbose)
                verbose=true
                ;;
            *)
                custom_params+=" ${1}"
                ;;
        esac
        shift
    done

    local cron_job="${cron_expr} ${command}${custom_params}"
    if cron_exists "${cron_expr}" "${command}"; then
        err "Cron job already exists"
        return 1
    fi

    echo "${cron_job}" >> "${LINX_CRON_JOBS_FILE}"

    stdout_target="/dev/null"
    stderr_target="${LINX_CRON_LOG_FILE}"
    if $verbose; then
        stdout_target="${LINX_CRON_LOG_FILE}"
    fi
    output_redirection=">> ${stdout_target} 2>> ${stderr_target}"
    (crontab -l 2>/dev/null; echo "${cron_job} ${output_redirection}") | crontab -

    ! $quiet && echo "Cron job created: ${cron_job}"
}

# @description Prompt the user for a value
# @param $1 The prompt message for the user
# @example
#  prompt "Desired filename:"
prompt() {
    local msg="${1}"
    read -p "${msg} " user_input
    echo "${user_input}"
}

prompt_multiline() {
    local input_type="${1:-your input}"
    echo "Please enter ${input_type} (type 'END' to finish):"
    input=""
    while IFS= read -r line; do
        if [[ "${line}" == "END" ]]; then
            break
        fi
        input="${input}${line}"$'\n'
    done
}

# @description Prompt the user for approval
# @param $1 The action to be confirmed
# @param $2 The prompt message for the user
# @return 0 if user confirms, 1 otherwise
# @example
#  # Abort on anything other than y or yes (case insensitive)
#  confirm "Installation" "Proceed?" --abort
#
#  # Use return status
#  if confirm "Installation" "Proceed?"; then
#    # on abort
#  else
#    # on confirm...
#  fi
confirm() {
    local abort=0
    if [[ $# -ge 3 && "$3" == "--abort" ]]; then
        abort=1
    fi
    echo -n "$2 (y/n): "
    read answer
    case $answer in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            echo "$1 aborted."
            if [[ abort -eq 1 ]]; then
                exit 1
            fi
            return 1
            ;;
    esac
}

has_uncommitted_changes() {
    if [[ $(git status --porcelain) ]]; then
        return 0
    else
        return 1
    fi
}

get_latest_stash_message() {
    git stash list -1 --pretty=format:%s | sed 's/^[^:]*: //'
}

# @description Determines whether an array contains the specified element
# @param $1 the element to look for
# @param $2 the array to process
# @return 0 if the element is found; 1 otherwise
# @example
#   array_contains "apple" "${fruits[@]}"
array_contains() {
    local needle="$1"
    shift
    local array=("$@")
    for element in "${array[@]}"; do
        if [[ "$element" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

resolve_directory_path() {
    local directory_path="${1:-.}"
    # Handle '~' for home directory
    if [[ "${directory_path}" == "~"* ]]; then
        directory_path="${directory_path/#\~/$HOME}"
    fi
    # Use readlink or realpath to get the absolute path
    if command -v realpath >/dev/null 2>&1; then
        directory_path="$(realpath -m -- "${directory_path}")"
    else
        directory_path="$(readlink -f -- "${directory_path}")"
    fi
    # Check that the specified directory exists on the file system
    if [[ ! -e "${directory_path}" ]]; then
        err "The specified directory does not exist: ${directory_path}" "path"
        return 1
    fi
    echo "${directory_path}"
}

# @description Remove leading and trailing whitespaces
# @example trim '     hello    world!      '
#          output: hello world
trim() {
    local s="${1}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    echo "$s"
}

# @description Remove the first line matching the specified substring
# @param $1 The file to process
# @param $2 The substring to match
# @example
#   remove_first_line_containing myfile "hello, world!"
remove_first_line_containing() {
    local file="$1"
    local substring="$2"
    if [[ ! -f "${file}" ]]; then
        err "File '${file}' does not exist."
        return 1
    fi
    if grep -q "${substring}" "${file}"; then
        local temp_file
        temp_file=$(mktemp)
        grep -v "$substring" "${file}" > "${temp_file}"
        mv "${temp_file}" "${file}"
        return 0
    else
        err "No entry found containing '${substring}' in file '${file}'."
        return 1
    fi
}

is_numeric() {
    if [[ $1 =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]; then
        return 0
    fi
    return 1
}

# @description Print an array with line numbers
# @param $1  the reference of the array to print
# @example
#   print_array my_array
print_array() {
    # Use nameref to reference the passed array
    local -n array_ref="$1"
    local line_number=1
    for line in "${array_ref[@]}"; do
        printf "[%d] %s\n" "$line_number" "$line"
        ((line_number++))
    done
}

# @description Determines whether a software is installed on this system
# @param $1 the software name
# @param $2 0 to mute echo messages; 1 otherwise
# @return 0 if the software is installed; 1 otherwise
#   installed firefox
# @example
installed() {
    local software="${1}"
    local quiet=false
    if [[ "${2}" == "-q" || "${2}" == "--quiet" ]]; then
        quiet=true
    fi
    if dpkg -s "${software}" &> /dev/null || compgen -G "${LINX_COMMANDS_DIR}/*${software}*" > /dev/null; then
        local location
        location=$(which "${software}")
        if ! $quiet; then
            echo "${software} is installed at ${location}"
        fi
        return 0
    else
        if ! $quiet; then
            echo "${software} is not installed."
        fi
        return 1
    fi
}

is_sourced() {
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        return 1
    fi
    return 0
}

cron_exists() {
    local cron_expr="${1}"
    local command="${2}"
    crontab -l 2>/dev/null | grep -q -F "${cron_expr} ${command}"
}

# @description Delete the element identified by the specified path. Supports regular files and directories.
# @param $1 the file or directory to delete
# @param $2 (optional) -q if the operation should mute outputs
# @return 0 if the operation completed successfully; 1 otherwise
# @example
#   del projects          # delete projects
#   del projects -q dirA  # delete projects, quietly
del() {
    require_sudo "delete the specified element."
    local quiet=false
    local path
    path=$(trim_slash "${1}")
    if [[ "${2}" == "-q" || "${2}" == "--quiet" ]]; then
        quiet=true
    fi
    if [[ -f "${path}" ]]; then
        sudo rm "${path}"
        ! $quiet && echo "Removed [file] ${path}"
        return 0
    fi
    if [[ -d "${path}" ]]; then
        sudo rm -r "${path}"
        ! $quiet && echo "Removed [dir] ${path}"
        return 0
    fi
    ! $quiet && echo "Could not find any file or directory at ${path}"
    return 1
}

# @description Retrieves the names of the files in the specified directory
# @param $1  the path of the directory to process
# @param $2  the name of the array to use for storing the file names
# @return an array of strings
# @example
#   get_file_names /home/john array_name
#   get_file_names .. array_name
#   get_file_names / array_name
get_file_names() {
    local directory=
    directory=$(resolve_directory_path "${1}")
    local array_nameref="${2}"
    local -n file_array="${array_nameref}"
    for file in "${directory}"/*; do
        if [[ -f "${file}" ]]; then
            filename=$(basename "${file}")
            file_array+=("${filename}")
        fi
    done
}

current_dir() {
    if is_sourced; then
        pwd
    else
        local script_dir
        script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
        echo "${script_dir}"
    fi
}

color() {
    local subject="${1}"
    local _color="${2:-"${RED}"}"
    echo "${_color}${subject}${NC}"
}

err() {
    local message="${1}"
    echo -e "$(color "E:") ${message}" >&2
}

# @description Append unique lines from source file that are missing in target file
# @param $1  The target file
# @param $2  The source file
# @example
#   Given
#   `file_a`
#   A
#   B
#   `file_b`
#   A
#   C
#   D
#   E
#
#   When
#   add_missing_lines file_a file_b
#
#   Then
#   `file_a`
#   A
#   B
#   C
#   D
#   E
add_missing_lines() {
    local target_file="${1}"
    local source_file="${2}"

    if [[ ! -f "${target_file}" ]]; then
        echo "Could not find file A at ${target_file}"
        return 1
    fi
    if [[ ! -f "${target_file}" ]]; then
        echo "Could not find file B at ${source_file}"
        return 1
    fi

    local temp_file
    temp_file=$(mktemp)
    grep -Fxvf "${target_file}" "${source_file}" >> "${temp_file}"
    cat "${temp_file}" >> "${target_file}"
    rm -f "${temp_file}"
}

add_missing_properties() {
    local target_file="${1}"
    local source_file="${2}"
    local tmp_target_keys tmp_new_properties tmp_new_file
    tmp_new_properties=$(mktemp)
    tmp_new_file=$(mktemp)
    tmp_target_keys=$(mktemp)

    awk -F= '{print $1}' "${target_file}" | while IFS= read -r key; do
        normalize_key "$key"
    done > "${tmp_target_keys}"

    while IFS= read -r line; do
        key=$(echo "${line}" | awk -F= '{print $1}')
        normalized_key=$(normalize_key "$key")
        if ! grep -q "^$normalized_key$" "${tmp_target_keys}"; then
          echo "${line}" >> "${tmp_new_properties}"
        fi
    done < "$source_file"

    cat "${target_file}" > "${tmp_new_file}"
    cat "${tmp_new_properties}" >> "${tmp_new_file}"
    cat "${tmp_new_file}" > "${target_file}"
    rm -f "${tmp_target_keys}" "${tmp_new_properties}" "$tmp_new_file"
}

normalize_key() {
  local key="${1}"
  echo "${key}" | awk '{gsub(/^[[:space:]]*#+[[:space:]]*|^[[:space:]]*/, ""); print}'
}

expand_path() {
    local input="${1}"
    input=${input//\"/}
    while [[ "$input" =~ (\$\{[a-zA-Z_][a-zA-Z0-9_]*\}) ]]; do
        local var=${BASH_REMATCH[1]}
        local var_name=${var:2:-1}
        local var_value=${!var_name}
        input=${input//$var/$var_value}
    done
    echo "${input}"
}

get_property() {
    local usage="Usage: get_property [file] [key] [[--quiet] [--default]]"
    local file="${1}"
    local key="${2}"
    local quiet=false
    local default_value
    shift 2

    while [[ $# -gt 0 ]]; do
        case $1 in
            -q|--quiet)
                quiet=true
                ;;
            -d|--default)
                default_value="${2}"
                shift
                ;;
            *)
                echo "${usage}"
                return 1
                ;;
        esac
        shift
    done

    if [[ -z "${file}" ]]; then
        ! $quiet && err "Could not find file ${file}"
        return 1
    fi

    while IFS='=' read -r k v; do
        k=$(trim "${k}")

        if [[ $k == "$key" ]]; then
            v=$(trim "${v}")
            # Remove leading/trailing quotes from the value
            v="${v#\"}"
            v="${v%\"}"
            echo "${v}"
            return 0
        fi
    done < "${file}"

    if [[ -n "${default_value}" ]]; then
        echo "${default_value}"
        return 0
    fi

    ! $quiet && err "Could not find key ${key} in file ${file}"
    return 1
}

put_property() {
    local file="${1}"
    local key="${2}"
    local value="${3}"
    local found=false
    local temp_file
    temp_file=$(mktemp)

    if [[ -z "${file}" ]]; then
        err "Could not find file ${file}"
        return 1
    fi
    while IFS='=' read -r k v; do
        k=$(trim "${k}")
        v=$(trim "${v}")
        key_trim=$(trim "${key}")
        value_trim=$(trim "${value}")
        if [[ -z "$k" ]]; then
            continue
        fi
        if [[ "$k" == "${key_trim}" ]]; then
            echo "${key_trim}=${value_trim}" >> "${temp_file}"
            found=true
        else
            echo "$k=$v" >> "${temp_file}"
        fi
    done < "$file"

    if ! $found; then
        echo "${key_trim}=${value_trim}" >> "${temp_file}"
        echo -e "Added $(color "${key_trim}" "${GREEN_BOLD}") = $(color "${value_trim}" "${YELLOW_BOLD}")"
    else
        echo -e "$(color "${key_trim}" "${GREEN_BOLD}") was set to $(color "${value_trim}" "${YELLOW_BOLD}")"
    fi

    mv "${temp_file}" "$file"
}

get_linx_property() {
    local args=("$@")
    local raw=false
    while [[ ${#args[@]} -gt 0 ]]; do
        case "${args[0]}" in
            -r|--raw)
                raw=true
                ;;
        esac
        args=("${args[@]:1}")
    done

    local value
    value="$(get_property "${LINX_CONFIG_FILE}" "$@")"
    if ! $raw && [[ -n "${value}" ]]; then
        expand_path "${value}"
    else
        echo "${value}"
    fi
}

put_linx_property() {
    local key="${1}"
    local value="${2}"
    put_property "${LINX_CONFIG_FILE}" "${key}" "${value}"
}

get_help() {
    cat "${LINX_HELP_DIR}/${1}.help"
}

anonymize_plain_text() {
    local input="${1}"
    local case_sensitive=false
    if [[ "${2}" == -c || "${2}" == --case-sensitive ]]; then
        case_sensitive=true
    fi

    local properties_file="${LINX_ANONYMIZE_FILE}"
    [[ ! -f "${properties_file}" ]] && err "Properties file missing at ${properties_file}" && return 1

    while IFS='=' read -r key value; do
        if [[ ! "${key}" =~ ^[[:space:]]*# ]]; then
            if $case_sensitive; then
                input="${input//$key/$value}"
            else
                lower_key="${key,,}"
                input="${input,,}"
                input="${input//$lower_key/$value}"
            fi
        fi
    done < "${properties_file}"
    echo "${input}"
}

backup_and_rotate() {
    local target="${1}"
    local quiet=''
    local max_backups=$TERMINATOR_BACKUPS_CAPACITY
    local backup_suffix=".bak"
    local timestamp dir_path file_name
    timestamp=$(date +"%Y%m%d%H%M%S")
    if [[ "${2}" == --quiet || "${2}" == -q ]]; then
        quiet="-q"
    fi

    dir_path=$(dirname "${target}")
    file_name=$(basename "${target}")
    local backup_prefix="${file_name}_"
    mapfile -t backups < <(find "${dir_path}" -maxdepth 1 -name "${backup_prefix}*${backup_suffix}" -printf '%T@ %p\n' | sort -n | cut -d' ' -f2-)

    if (( ${#backups[@]} >= max_backups )); then
        local to_delete=$(( ${#backups[@]} - max_backups + 1 ))
        for ((i=0; i<to_delete; i++)); do
            rm -f "${backups[$i]}"
        done
    fi

    cpv "${target}" "${dir_path}/${backup_prefix}${timestamp}${backup_suffix}"
}

linx_spinner() {
    echo -n ' '; while true; do for X in '-' '/' '|' '\'; do echo -en "\r$X"; sleep 0.1; done; done
}

linx_spinner_start() {
    linx_spinner &
    LINX_SPINNER_PID=$!
}

linx_spinner_stop() {
    if [ -n "${LINX_SPINNER_PID}" ]; then
        kill "${LINX_SPINNER_PID}" 2>/dev/null
        wait "${LINX_SPINNER_PID}" 2>/dev/null || true
        LINX_SPINNER_PID=""
        echo -en "\r \r"
    fi
}

require_sudo() {
    local action="${1}"
    echo "This will ${action}"
    if ! sudo -v; then
        err "This action requires sudo privileges. Please provide valid credentials."
        exit 1
    fi
}

request_dir() {
    local var="${1}"
    local var_name="${2}"
    if [[ -n "${var}" ]]; then
        cs "${var}"
    else
        echo "\$${var_name} environment variable is not defined. You can set it in ~/.bashrc"
        return 1
    fi
}

install_dependency() {
    local software="${1}"
    local reason="${2}"
    if ! installed "${software}" --quiet; then
        if ! $auto_approve && confirm "${LINX_PROJECT}: ${software} installation" "${LINX_PROJECT}: Do you wish to install ${software} ${reason}?"; then
            sudo apt install "${software}"
        fi
    fi
}

install_command() {
    local filename="${1}"
    local command_name filepath
    command_name=$(basename "${filename}" .sh)
    filepath="commands/executables/${command_name}.sh"
    chmod +x "${filepath}"
    sudo cp "${filepath}" "${LINX_COMMANDS_DIR}"/"${command_name}"
    echo "${command_name}" >> "${LINX_INSTALLED_COMMANDS}"
    cp -rf "help/${command_name}"/* "${LINX_HELP_DIR}"/
}

get_goal() {
    local installed="${1}"
    if [[ $installed -eq 0 ]]; then
        echo "synchronized";
    else
        echo "installed";
    fi
}

is_linx_installed() {
    if [[ -d "${LINX_DIR}" ]]; then
        return 0
    else
        return 1
    fi
}

third_party_themes_installed() {
    local file="${TERMINATOR_THEME_POLICY_FILE}"
    if [[ -f "${file}" ]] && grep -q "${TERMINATOR_THIRD_PARTY_ENABLED_KEY}=true" "${file}"; then
        return 0
    fi
    return 1
}

should_install_third_party_themes() {
    local msg="${LINX_PROJECT}: Do you wish to install pre-approved, third-party terminator themes?"
    if ($fresh_install || ! is_sourced && ! $auto_approve && confirm "Third-party themes installation" "${msg}"); then
        return 0
    fi
    if ([[ $linx_already_installed -eq 0 ]] && third_party_themes_installed) || \
       ([[ $linx_already_installed -ne 0 ]] && \
       ( $auto_approve || confirm "Third-party themes installation" "${msg}")); then
        return 0
    else
        return 1
    fi
}

install_terminator_config() {
    local third_party_themes_enabled=false
    local default_theme user_theme user_layout
    local default_layout="grid"

    mkdir -p "${TERMINATOR_DIR}"
    if [[ -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        backup_and_rotate "${TERMINATOR_CONFIG_FILE}" -q
    fi

    if should_install_third_party_themes; then
        echo "Downloading third-party themes..."
        linx_spinner_start
        if git clone "${TERMINATOR_THEMES_REPOSITORY}" --single-branch -q; then
            linx_spinner_stop
            default_theme="${TERMINATOR_DEFAULT_THEME_THIRD_PARTY}"
            third_party_themes_enabled=true
        else
            err "Could not clone repository ${TERMINATOR_THEMES_REPOSITORY}"
            return 1
        fi
    else
        default_theme="${TERMINATOR_DEFAULT_THEME_NATIVE}"
    fi

    if [[ ! -f "${TERMINATOR_CURRENT_THEME_FILE}" ]]; then
        echo "${default_theme}" > "${TERMINATOR_CURRENT_THEME_FILE}"
    fi
    if [[ ! -f "${TERMINATOR_CURRENT_LAYOUT_FILE}" ]]; then
        echo "${default_layout}" > "${TERMINATOR_CURRENT_LAYOUT_FILE}"
    fi
    user_theme=$(cat "${TERMINATOR_CURRENT_THEME_FILE}")
    user_layout=$(cat "${TERMINATOR_CURRENT_LAYOUT_FILE}")

    # generate the new configuration file
    echo '' > "${TERMINATOR_CONFIG_FILE}"

    add_fragment "global"
    add_fragment "shortcuts"
    echo "[profiles]" >> "${TERMINATOR_CONFIG_FILE}"
    echo "  [[default]]" >> "${TERMINATOR_CONFIG_FILE}"
    add_fragment "themes"
    if $third_party_themes_enabled; then
        echo "Installing third-party themes..."
        cat "${TERMINATOR_THEMES_PROJECT}/terminator.conf" >> "${TERMINATOR_CONFIG_FILE}"
        echo "${TERMINATOR_THIRD_PARTY_ENABLED_KEY}=true" > "${TERMINATOR_THEME_POLICY_FILE}"
    fi
    add_fragment "layouts"
    add_fragment "plugins"

    term profiles --set "${user_theme}"
    term layouts --set "${user_layout}"
}

add_fragment() {
    local fragment="${1}"
    cat "${TERMINATOR_LOCAL_CONFIG_DIR}/${fragment}.conf" >> "${TERMINATOR_CONFIG_FILE}"
}

trim_slash() {
    string="${1}"
    trimmed_string=${string%/}
    echo "${trimmed_string}"
}

is_git_repo() {
    local quiet=false
    if [[ "${1}" == "-q" ]]; then
        quiet=true
    fi
    if git rev-parse --git-dir > /dev/null 2>&1; then
        return 0
    else
        if ! $quiet; then
            err "$(pwd) is not a git repository"
        fi
        return 1
    fi
}

git_get_branch_name() {
    git rev-parse --abbrev-ref HEAD
}

##############################################################
# Installation process
##############################################################

install_commands() {
    sudo mkdir -p "${LINX_COMMANDS_DIR}"
    printf '' > "${LINX_INSTALLED_COMMANDS}"
    mapfile -t COMMANDS < <(find ./commands/executables -maxdepth 1 -type f -printf "%f\n")
    for command in "${COMMANDS[@]}"; do
        install_command "${command}"
    done
    cp "commands/.autocomplete.sh" "${LINX_DIR}"
    sudo cp -rf "commands/executables/ask.server" "${LINX_COMMANDS_DIR}"
}

update_mkf_config() {
    cat "config/mkf/mkf_config" > "${MKF_CONFIG_FILE}"
    cp -rf "config/mkf/templates"/* "${MKF_TEMPLATE_DIR}"
}

# @description Sync with the latest version from the remote
# @param $1 (Optional) the name of the branch to clone
# @return 0 if the configuration was synchronized successfully; 1 otherwise
install_core() {
    local branch_name install_dir
    branch_name="${1:-main}"
    install_dir=$(mktemp -d)
    cd "${install_dir}" || { rm -rf "${install_dir}"; err "Could not cd into temp install directory"; exit 1; }
    echo "${LINX_PROJECT}: Cloning remote... [${branch_name}]"
    linx_spinner_start
    if git clone "${LINX_REPOSITORY}" --branch "${branch_name}" --single-branch -q; then
        linx_spinner_stop
        cd "${LINX_PROJECT}" || return 1
        cp ./install.sh "${LINX_DIR}/${LINX_LIB_FILE_NAME}"
        cp "${LINX_FUNC_FILE_NAME}" "${LINX_DIR}"
        if [[ ! -f "${LINX_ANONYMIZE_FILE}" ]]; then
            cp ./config/anonymize.properties "${LINX_ANONYMIZE_FILE}"
        fi
        add_missing_properties "${LINX_CONFIG_FILE}" ./config/config.properties
        source "${HOME}/.bashrc"
        update_mkf_config
        install_commands
        # update linx
        if ! cp 'uninstall.sh' "${LINX_DIR}"; then
            err "Could not copy uninstall.sh to ${LINX_DIR}"
        fi
        if ! install_terminator_config; then
            err "Could not update terminator configuration"
            return 1
        fi
        # Clean up temp files & refresh shell session
        cd ../..
        echo "${LINX_PROJECT}: Removing temporary files..."
        if ! rm -rf "${install_dir}"; then
            err "Could not remove ${install_dir} directory"
        fi
        echo "${LINX_PROJECT}: Remote cloned"
        return 0
    else
        echo "E: Could not clone repository ${LINX_REPOSITORY}"
        return 1
    fi
}

update_rc_file() {
    local rc_file="${1}"
    local target=~/"${rc_file}"
    local WATERMARK="Created by \`linx\`"
    local SEPARATOR="##############################################################"
    DATETIME="$(date "+%Y-%m-%d %H:%M:%S")"
    # Check if the wizard should source linx in .bashrc
    if [[ -f "${target}" ]] && ! grep -qF "${WATERMARK}" "${target}"; then
        lines="\n${SEPARATOR}\n"
        lines+="# ${WATERMARK} on ${DATETIME}"
        lines+="\n${SEPARATOR}\n\n"
        lines+=$(cat config/bashrc_config)
        lines+="\n"
        lines+="\n${SEPARATOR}\n"
        lines+="# End of linx configuration"
        lines+="\n${SEPARATOR}\n\n"
        echo -e "${lines}" >> "${target}"
    fi
}

install_dependencies() {
    if [[ $linx_already_installed -ne 0 ]]; then
        install_dependency git 'for version management'
        install_dependency terminator 'as a terminal emulator'
        install_dependency neofetch 'as a system information tool'
        install_dependency zip 'as a file compression utility'
        install_dependency simplescreenrecorder 'as a screen recorder'
        install_dependency rsync 'for copying / transferring files'
        install_dependency nodejs 'for using ChatGPT in your terminal'
        install_dependency npm 'for using ChatGPT in your terminal'
    fi
}

setup_vim() {
    local VIM_CONFIG_FILE="${HOME}/.vimrc"
    if [[ ! -f "${VIM_CONFIG_FILE}" ]]; then
        cat config/vim_config > "${VIM_CONFIG_FILE}"
        echo "Added vim configuration to ${VIM_CONFIG_FILE}"
    fi
}

# @description Sync with the latest version of functions/aliases and Terminator profiles from the remote
# @param $1 (optional) 0 if first install; 1 otherwise
# @return 0 if the configuration was synchronized successfully; 1 otherwise
install_linx() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                auto_approve=true
                ;;
            --fresh)
                fresh_install=true
                ;;
            *)
                echo "Usage: ./install.sh [-y]"
                return 1
                ;;
        esac
        shift
    done
    require_sudo "install ${LINX_PROJECT} on your system."

    mkdir -p "${LINX_DIR}"
    mkdir -p "${LINX_HELP_DIR}"
    mkdir -p "${MKF_TEMPLATE_DIR}"
    mkdir -p "${LINX_CRON_DIR}"
    mkdir -p "${DOCKER_CONFIG_DIR}"
    touch "${LINX_CRON_JOBS_FILE}"
    touch "${DOCKER_KEEP_CONTAINERS_FILE}"
    touch "${DOCKER_KEEP_IMAGES_FILE}"

    update_rc_file ".bashrc"
    update_rc_file ".zshrc"
    if ! install_core "$@"; then
        return 1
    fi
    if install_dependencies "$@" && [[ $linx_already_installed -eq 0 ]]; then
        echo "${LINX_PROJECT}: Restart your terminal for all changes to be applied."
    fi
    if ! setup_vim; then
        return 1
    fi
    local success goal
    success=$(is_linx_installed)
    goal=$(get_goal $linx_already_installed)
    if [[ $success -eq 0 ]]; then
        echo "${LINX_PROJECT} was ${goal} successfully."
        echo -e "Current version: $(color "$(linx -v)" "${GREEN_BOLD}")"
    else
        echo "Failed to install ${LINX_PROJECT}"
        return 1
    fi
}

##############################################################
# Global variables
##############################################################

is_linx_installed
linx_already_installed=$?

##############################################################
# Bootstrap
##############################################################

# Only install linx if this file is executed
if ! is_sourced "$@"; then
    install_linx "$@"
fi
