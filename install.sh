#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

##############################################################
# Constants
##############################################################

export VERSION="1.0.0-alpha3"
export PROJECT="linx"
export LINX_DIR="${HOME}/${PROJECT}"
export CRON_DIR="${LINX_DIR}/cron"
export CRON_JOBS_FILE="${CRON_DIR}/installed.log"
export CRON_LOG_FILE="${CRON_DIR}/jobs.log"
INSTALL_DIR="tmp-linx-install"
LINX_INSTALLED_COMMANDS="${LINX_DIR}/installed_commands"
DOCKER_CONFIG_DIR="${HOME}/docker_config"
KEEP_CONTAINERS_FILE="${DOCKER_CONFIG_DIR}/keep_containers"
KEEP_IMAGES_FILE="${DOCKER_CONFIG_DIR}/keep_images"
FUNC_FILE_NAME="${PROJECT}.sh"
LIB_FILE_NAME=".${PROJECT}_lib.sh"
TERMINATOR_DIR="${HOME}/.config/terminator"
TERMINATOR_CONFIG_FILE="${TERMINATOR_DIR}/config"
CURRENT_THEME_FILE="${TERMINATOR_DIR}/current.profile"
CURRENT_LAYOUT_FILE="${TERMINATOR_DIR}/current.layout"
THEME_POLICY_FILE="${TERMINATOR_DIR}/theme_policy"
GITHUB_ACCOUNT="https://github.com/Julien-Fischer"
REPOSITORY="${GITHUB_ACCOUNT}/${PROJECT}.git"
TERMINATOR_LOCAL_CONFIG_DIR="config/terminator"
TERMINATOR_THEMES_PROJECT="terminator_themes"
TERMINATOR_THEMES_REPOSITORY="${GITHUB_ACCOUNT}/${TERMINATOR_THEMES_PROJECT}.git"
TERMINATOR_DEFAULT_THEME_NATIVE="contrast"
TERMINATOR_DEFAULT_THEME_THIRD_PARTY="synthwave_2"
THIRD_PARTY_ENABLED_KEY="third_party_themes_enabled"

# Basic ANSI colors with no styles (bold, italic, etc)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'


##############################################################
# Parameters
##############################################################

auto_approve=1

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
                err "Invalid parameter: '${1}'"
                return 1
                ;;
        esac
    shift
    done

    local cron_job="${cron_expr} ${command}"
    if cron_exists "${cron_expr}" "${command}"; then
        err "Cron job already exists"
        return 1
    fi

    echo "${cron_job}" >> "${CRON_JOBS_FILE}"

    stdout_target="/dev/null"
    stderr_target="${CRON_LOG_FILE}"
    if $verbose; then
        stdout_target="${CRON_LOG_FILE}"
    fi
    output_redirection=">> ${stdout_target} 2>> ${stderr_target}"
    (crontab -l 2>/dev/null; echo "${cron_job} ${output_redirection}") | crontab -

    ! $quiet && echo "Cron job created: ${cron_job}"
}



# @description Prompt the user for a value
# @param $1 The prompt message for the user
# @example
#  prompt "Desired filename:"
function prompt() {
    local msg="${1}"
    read -p "${msg} " user_input
    echo "${user_input}"
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
#  if [[ confirm "Installation" "Proceed?"]]; then
#    # on abort
#  else
#    # on confirm...
#  fi
function confirm() {
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

# @description Determines whether a software is installed on this system
# @param $1 the software name
# @param $2 0 to mute echo messages; 1 otherwise
# @return 0 if the software is installed; 1 otherwise
#   installed firefox
# @example
installed() {
    local software="${1}"
    local quiet="${2:-1}"
    if dpkg -s "${software}" &> /dev/null || ls /usr/local/bin | grep -q "${software}"; then
        local location=$(which "${software}")
        if [[ $quiet -ne 0 ]]; then
            echo "${software} is installed at ${location}"
        fi
        return 0
    else
        if [[ $quiet -ne 0 ]]; then
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
    local path=$(trim_slash "${1}")
    local quiet=false
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

current_dir() {
    if is_sourced; then
        pwd
    else
        local script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
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
    echo -e "$(color "E:") ${message}"
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
    local quiet=0
    if ! installed "${software}" $quiet; then
        if [[ $auto_approve -ne 0 ]] && confirm "${PROJECT}: ${software} installation" "${PROJECT}: Do you wish to install ${software} ${reason}?"; then
            sudo apt install "${software}"
        fi
    fi
}

install_command() {
    local command_name=$(basename "${1}" .sh)
    local filepath="commands/${command_name}.sh"
    chmod +x "${filepath}"
    sudo cp "${filepath}" /usr/local/bin/"${command_name}"
    echo "${command_name}" >> "${LINX_INSTALLED_COMMANDS}"
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
    local file="${THEME_POLICY_FILE}"
    if [[ -f "${file}" ]] && grep -q "${THIRD_PARTY_ENABLED_KEY}=true" "${file}"; then
        return 0
    fi
    return 1
}

should_install_third_party_themes() {
    local msg="${PROJECT}: Do you wish to install pre-approved, third-party terminator themes?"
    if ([[ $linx_already_installed -eq 0 ]] && third_party_themes_installed) || ([[ $linx_already_installed -ne 0 ]] && ([[ $auto_approve -eq 0 ]] || confirm "Third-party themes installation" "${msg}")); then
        return 0
    else
        return 1
    fi
}

install_terminator_config() {
    local third_party_themes_enabled=1
    local default_theme=
    local default_layout="grid"

    mkdir -p "${TERMINATOR_DIR}"
    if [[ -f "${TERMINATOR_CONFIG_FILE}" ]]; then
        backup "${TERMINATOR_CONFIG_FILE}" -q
    fi

    if should_install_third_party_themes; then
        echo "Downloading third-party themes..."
        if git clone "${TERMINATOR_THEMES_REPOSITORY}"; then
            default_theme="${TERMINATOR_DEFAULT_THEME_THIRD_PARTY}"
            third_party_themes_enabled=0
        else
            err "Could not clone repository ${TERMINATOR_THEMES_REPOSITORY}"
            return 1
        fi
    else
        default_theme="${TERMINATOR_DEFAULT_THEME_NATIVE}"
    fi

    if [[ ! -f "${CURRENT_THEME_FILE}" ]]; then
        echo "${default_theme}" > "${CURRENT_THEME_FILE}"
    fi
    if [[ ! -f "${CURRENT_LAYOUT_FILE}" ]]; then
        echo "${default_layout}" > "${CURRENT_LAYOUT_FILE}"
    fi
    local user_theme=$(cat "${CURRENT_THEME_FILE}")
    local user_layout=$(cat "${CURRENT_LAYOUT_FILE}")

    # generate the new configuration file
    echo '' > "${TERMINATOR_CONFIG_FILE}"

    add_fragment "global"
    add_fragment "shortcuts"
    echo "[profiles]" >> "${TERMINATOR_CONFIG_FILE}"
    echo "  [[default]]" >> "${TERMINATOR_CONFIG_FILE}"
    add_fragment "themes"
    if [[ $third_party_themes_enabled -eq 0 ]]; then
        echo "Installing third-party themes..."
        cat "${TERMINATOR_THEMES_PROJECT}/terminator.conf" >> "${TERMINATOR_CONFIG_FILE}"
        echo "${THIRD_PARTY_ENABLED_KEY}=true" > "${THEME_POLICY_FILE}"
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

##############################################################
# Installation process
##############################################################

install_commands() {
    sudo mkdir -p /usr/local/bin
    printf '' > "${LINX_INSTALLED_COMMANDS}"
    mapfile -t COMMANDS < <(ls -1 ./commands)
    for command in "${COMMANDS[@]}"; do
        install_command "${command}"
    done
}

# @description Sync with the latest version from the remote
# @return 0 if the configuration was synchronized successfully; 1 otherwise
install_core() {
    mkdir -p "${INSTALL_DIR}"
    cd "${INSTALL_DIR}" || rm -rf "${INSTALL_DIR}"
    if git clone "${REPOSITORY}"; then
        cd "${PROJECT}" || return 1
        cp ./install.sh "${LINX_DIR}/${LIB_FILE_NAME}"
        cp "${FUNC_FILE_NAME}" "${LINX_DIR}"
        source "${HOME}/.bashrc"
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
        echo "${PROJECT}: Removing temporary files..."
        if ! rm -rf "${INSTALL_DIR}"; then
            err "Could not remove ${INSTALL_DIR} directory"
        fi
        return 0
    else
        echo "E: Could not clone repository ${REPOSITORY}"
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
        echo -e "${lines}" >> "${target}"
    fi
}

install_dependencies() {
    if [[ $linx_already_installed -ne 0 ]]; then
        install_dependency git 'for version management'
        install_dependency terminator 'as a terminal emulator'
        install_dependency neofetch 'as a system information tool'
        install_dependency mkf 'to generate timestamped files from templates'
    fi
}

# @description Sync with the latest version of functions/aliases and Terminator profiles from the remote
# @param $1 (optional) 0 if first install; 1 otherwise
# @return 0 if the configuration was synchronized successfully; 1 otherwise
#
install_linx() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                auto_approve=0
                shift
                ;;
            *)
                echo "Usage: ./install.sh [-y]"
                return 1
                ;;
        esac
    done
    echo "this will install ${PROJECT} on your system."
    [[ $auto_approve -ne 0 ]] && confirm "Installation" "Proceed?" --abort

    mkdir -p "${LINX_DIR}"
    mkdir -p "${CRON_JOBS_FILE}"
    mkdir -p "${DOCKER_CONFIG_DIR}"
    touch "${KEEP_CONTAINERS_FILE}"
    touch "${KEEP_IMAGES_FILE}"

    update_rc_file ".bashrc"
    update_rc_file ".zshrc"
    if ! install_core "$@"; then
        return 1
    fi
    if install_dependencies "$@" && [[ $linx_already_installed -eq 0 ]]; then
        echo "${PROJECT}: Restart your terminal for all changes to be applied."
    fi
    local success=$(is_linx_installed)
    local goal=$(get_goal $linx_already_installed)
    if [[ $success -eq 0 ]]; then
        echo "${PROJECT} was ${goal} successfully."
    else
        echo "Failed to install ${PROJECT}"
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
