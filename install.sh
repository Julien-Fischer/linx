#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

##############################################################
# Constants
##############################################################

export VERSION="1.0.0-alpha2"
PROJECT="linx"
INSTALL_DIR="tmp-linx-install"
LINX_DIR=~/linx
KEEP_CONTAINERS_FILE="${LINX_DIR}/keep_containers"
KEEP_IMAGES_FILE="${LINX_DIR}/keep_images"
FUNC_FILE_NAME="${PROJECT}.sh"
LIB_FILE_NAME=".${PROJECT}_lib.sh"
TERMINATOR_DIR=~/.config/terminator
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

export COMMANDS=("term" "linx" "backup" "port")

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
keep_alive=1

##############################################################
# Utils
##############################################################

# @description Prompts the user for approval
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

timestamp() {
    local ds="${1-'-'}"
    local dts="${2-' '}"
    local ts="${3-':'}"
    date "+%Y${ds}%m${ds}%d${dts}%H${ts}%M${ts}%S"
}

is_sourced() {
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        return 1
    fi
    return 0
}

# @description Copy files with a progress bar
# @param $1 the file or directory to copy
# @param $2 the destination
# @return 0 if the operation completed successfully; 1+ otherwise
# @example
#   cpv projects dirA  # copies projects into dirA
#   cpv projects/ dirA  # copies all files and directories from projects into dirA
cpv() {
    local src="${1}"
    local dest="${2:-.}"
    rsync "${src}" "${dest}" -ah --info=progress2 --partial
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
    local quiet=${2:-''}
    if [[ -f "${path}" ]]; then
        sudo rm "${path}"
        [[ $quiet != "-q" ]] && echo "Removed [file] ${path}"
        return 0
    fi
    if [[ -d "${path}" ]]; then
        sudo rm -r "${path}"
        [[ $quiet != "-q" ]] && echo "Removed [dir] ${path}"
        return 0
    fi
    [[ $quiet != "-q" ]] && echo "Could not find any file or directory at ${path}"
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
    local command_name="${1}"
    local filepath="commands/${command_name}.sh"
    chmod +x "${filepath}"
    sudo cp "${filepath}" /usr/local/bin/"${command_name}"
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
    if [[ -f ~/linx.sh && -f ~/.linx_lib.sh ]]; then
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
    if should_install_third_party_themes; then
        echo "Downloading third-party themes..."
        if git clone "${TERMINATOR_THEMES_REPOSITORY}"; then
            default_theme="${TERMINATOR_DEFAULT_THEME_THIRD_PARTY}"
            third_party_themes_enabled=0
        else
            echo -e "$(color "E:") Could not clone repository ${TERMINATOR_THEMES_REPOSITORY}"
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

    # generate the configuration file
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

is_comment() {
    local line="${1}"
    if [[ "${line}" =~ ^[[:space:]]*# ]]; then
        return 0
    else
        return 1
    fi
}

trim_slash() {
    string="${1}"
    trimmed_string=${string%/}
    echo "${trimmed_string}"
}

##############################################################
# Installation process
##############################################################

# @description Sync with the latest version from the remote
# @return 0 if the configuration was synchronized successfully; 1 otherwise
install_core() {
    mkdir -p "${INSTALL_DIR}" && cd "${INSTALL_DIR}" || return 1
    if git clone "${REPOSITORY}"; then
        INSTALL_PATH="${INSTALL_DIR}/${PROJECT}"
        cd "${PROJECT}" || return 1
        cp "install.sh" ~/"${LIB_FILE_NAME}"
        # Install linx-native commands
        for command in "${COMMANDS[@]}"; do
            install_command "${command}"
        done
        # Update terminator settings
        mkdir -p "${TERMINATOR_DIR}"
        if [[ -f "${TERMINATOR_CONFIG_FILE}" ]]; then
            backup "${TERMINATOR_CONFIG_FILE}" -q
        fi
        install_terminator_config
        if [[ ! $? ]]; then
            return 1
        fi
        # Backup & update .linx.sh
        backup "${FUNC_FILE_NAME}" -q
        cp "${FUNC_FILE_NAME}" ~
        # Clean up temp files & refresh shell session
        cd ../..
        echo "${PROJECT}: Removing temporary files..."
        if ! rm -rf "${INSTALL_DIR}"; then
            echo -e "$(color "E:") Could not remove ${INSTALL_DIR} directory"
        fi
        source "${HOME}/.bashrc"
        return 0
    else
        echo -e "$(color "E:") Could not clone repository ${REPOSITORY}"
        return 1
    fi
}

update_rc_file() {
    local rc_file="${1}"
    local target=~/"${rc_file}"
    local WATERMARK="Created by \`linx\`"
    DATETIME="$(timestamp)"
    # Check if the wizard should source linx in .bashrc
    if [[ -f "${target}" ]] && ! grep -qF "${WATERMARK}" "${target}"; then
        lines="\n##############################################################\n"
        lines+="# ${WATERMARK} on ${DATETIME}"
        lines+="\n##############################################################\n\n"
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

    if [[ "${1}" == "-y" ]]; then
        auto_approve=0
    fi
    echo "this will install ${PROJECT} on your system."
    [[ $auto_approve -ne 0 ]] && confirm "Installation" "Proceed?" --abort

    mkdir -p "${LINX_DIR}"
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
