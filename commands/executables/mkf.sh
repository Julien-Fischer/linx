#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi

##############################################################
# Constants
##############################################################

readonly CURRENT_DATE="$(date +%Y-%m-%d)"
readonly CURRENT_TIME="$(date +%H-%M-%S)"
SCRIPT_NAME=$(basename "$0")

declare -A HANDLERS=(
    # long version
    ["config"]="handle_settings"
    ["template"]="handle_template"
    ["uninstall"]="handle_uninstall"
    ["upgrade"]="handle_upgrade"
    # Shorthands
    ["c"]="handle_settings"
    ["t"]="handle_template"
    ["d"]="handle_uninstall"
    ["u"]="handle_upgrade"
)

##############################################################
# Input
##############################################################

declare -A PARAMETERS=(
    [filename]=""
    [directory]="."
    [extension]=""
    [content]=""
    [software]=""
    [template_name]=""
    [auto_open]=0
    [datetime]=0
)

##############################################################
# Computed values
##############################################################

formatted_date=$CURRENT_DATE
formatted_filename=""
directory_path=""
declare -a tags_cache=()

##############################################################
# Utils
##############################################################

# @description Determines whether the specified string is a parameter value
# @param $1 the string to process
# @return 0 if the element is a non-empty string that does not start with a dash character; 1 otherwise
# @example
#   has_value "$2"
has_value() {
    [[ -n "$1" && "$1" != -* ]] && return 0 || return 1
}

# @description Throws an error if the specified parameter has no value
# @param $1 the name of the parameter
# @param $1 the parameter value to check
# @return 0 if the value is a non-empty string that does not start with a dash character; 1 otherwise
# @example
#   require_value "$1" "${1#*=}"
require_value() {
    if ! has_value "$2"; then
        fail "$1 requires a value" "parameter"
    fi
}

fail() {
    local attempt="${2:-option}"
    echo "${SCRIPT_NAME}: Invalid ${attempt}: $1"
    echo
    print_help
    exit 1
}

format_date() {
    if [[ "${PARAMETERS["datetime"]}" -eq 1 ]]; then
        formatted_date="${CURRENT_DATE}_${CURRENT_TIME}"
    fi
}

format_filename() {
    formatted_filename="${formatted_date}"
    if [[ -n "${PARAMETERS["basic"]}" ]]; then
        formatted_filename="$(timestamp --basic)"
    fi
    if [[ -n "${PARAMETERS["filename"]}" ]]; then
        formatted_filename+="_${PARAMETERS["filename"]}"
    fi
    if [[ -n "${PARAMETERS["extension"]}" ]]; then
        formatted_filename+=".${PARAMETERS["extension"]}"
    fi
}

generate_file() {
    directory_path=$(resolve_directory_path "${PARAMETERS["directory"]}")
    format_date
    format_filename
    write_file
    if [[ ${PARAMETERS["auto_open"]} -eq 1 ]]; then
        open_file
    fi
    echo -e "created: $(color "${formatted_filename}" "${GREEN_BOLD}") in: $(color "${directory_path}" "${YELLOW_BOLD}")"
}

write_file() {
    cd "${directory_path}" || echo "Can not cd to ${directory_path}"
    if [[ -f "$formatted_filename" ]]; then
        confirm "Operation" "File '${formatted_filename}' already exists in ${directory_path}. Do you want to override it?" --abort
    fi;
    echo "${PARAMETERS["content"]}" > "${formatted_filename}"
    local template_name=${PARAMETERS["template_name"]}
    if [[ -n "${template_name}" ]]; then
        local template_file="${MKF_TEMPLATE_DIR}/${template_name}"
        if [[ ! -e "${template_file}" ]]; then
            echo "${SCRIPT_NAME}: Could not find template ${template_name} in ${MKF_TEMPLATE_DIR}"
            list_templates
            exit 1
        fi
        local text=$(cat "${template_file}")
        printf "%s\n" "${text//\$\{CURRENT_DATE\}/${CURRENT_DATE}}" > "${formatted_filename}"
    fi
}

open_file() {
    local software="${PARAMETERS["software"]}"
    if [[ -z "${software}" ]]; then
        # use default software to open the file
        echo "opening ${formatted_filename}"
        xdg-open "$formatted_filename" &
        disown
    else
        echo "opening ${formatted_filename} using ${software}"
        "$software" "${formatted_filename}"
    fi
}

##############################################################
# Template
##############################################################

list_templates() {
    local templates=()
    get_file_names "${MKF_TEMPLATE_DIR}" "templates"
    template_count=${#templates[@]}
    if [[ $template_count -eq 0 ]]; then
        echo "No template in ${MKF_TEMPLATE_DIR}"
        return 0
    fi
    echo "Found ${template_count} templates:"
    printf "  - %s\n" "${templates[@]}"
}

delete_template() {
    local name="${1}"
    local option="${2}"
    local force=1
    if [[ "${option}" =~ ^(-y|--yes)$ ]]; then
        force=0
    fi
    local template="${MKF_TEMPLATE_DIR}/${name}"
    if [[ -e "${template}" ]]; then
        echo "This will delete the '${name}' template."
        [[ $force -ne 1 ]] && confirm "Deletion" "Are you sure you want to proceed?" --abort
        sudo rm "${template}"
        echo "Deleted ${name} template."
    else
        err "Could not locate ${name} in ${MKF_TEMPLATE_DIR}"
    fi
}

# @description Set a template with the specified name and content, erasing any existing one
# @param $1 the name of the template to create
# @param $2 the template content
# @return 0 if the template could be installed; 1 otherwise
# @example
#   put_template "demo" 'Hello, world!'
put_template() {
    local name="${1}"
    local content="${2}"
    local path="${MKF_TEMPLATE_DIR}/${name}"
    if [[ -e "${path}" ]]; then
        echo 'This template already exists.'
        confirm 'Template creation' 'Are you sure you want to proceed?' --abort
    fi
    echo "${content}" > "${name}"
    sudo mv "${name}" "${path}"
    echo -e "Installed template $(color "${name}" "${GREEN_BOLD}")."
}

read_template() {
    local name="${1}"
    local path="${MKF_TEMPLATE_DIR}"/"${name}"
    if [[ -e "${path}" ]]; then
        local text=$(cat "${path}")
        printf "%s\n" "${text//\$\{CURRENT_DATE\}/${CURRENT_DATE}}"
    else
        err "Could not locate template file '${name}' in ${MKF_TEMPLATE_DIR}"
        list_templates
        return 1
    fi
}

##############################################################
# Settings
##############################################################

put_setting() {
    local key="${1}"
    local value="${2}"
    put_property "${MKF_CONFIG_FILE}" "${key}" "${value}"
}


read_settings() {
    cat "${MKF_CONFIG_FILE}"
}

read_setting() {
    local key="${1}"
    if ! get_property "${MKF_CONFIG_FILE}" "${key}"; then
        echo "Available settings:"
        read_settings
        return 1
    fi
}

##############################################################
# Help
##############################################################

print_help() {
    local text=$(get_help "${SCRIPT_NAME}")
    printf "%s\n" "${text//\$\{MKF_TEMPLATE_DIR\}/${MKF_TEMPLATE_DIR}}"
}

print_template_help() {
    local text=$(get_help "${SCRIPT_NAME}-template")
    printf "%s\n" "${text//\$\{MKF_TEMPLATE_DIR\}/${MKF_TEMPLATE_DIR}}"
}

print_settings_help() {
    local text=$(get_help "${SCRIPT_NAME}-config")
    printf "%s\n" "${text//\$\{LINX_DIR\}/${LINX_DIR}}"
}

##############################################################
# Template
##############################################################

handle_template() {
    if [[ $# -eq 0 ]]; then
        list_templates
        return 0
    fi
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_template_help
                exit 0
                ;;
            -p|--path)
                echo "${MKF_TEMPLATE_DIR}"
                exit 0
                ;;
            -l|--list)
                list_templates
                exit 0
                ;;
            read)
                read_template "${2}"
                shift 2
                ;;
            rm)
                require_value "${1}" "${2}"
                delete_template "${2}" "${3}"
                shift 2
                ;;
            put)
                require_value "${1}" "${2}"
                require_value "${1}" "${3}"
                put_template "${2}" "${3}"
                shift 3
                ;;
            *)
                fail "$*"
                ;;
        esac
    done
}

handle_settings() {
    if [[ $# -eq 0 ]]; then
        read_settings
        return 0
    fi
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_settings_help
                return 0
                ;;
            -p|--path)
                echo "${MKF_CONFIG_FILE}"
                return 0
                ;;
            -l|--list)
                read_settings
                return 0
                ;;
            read)
                require_value "${1}" "${2}"
                read_setting "${2}"
                shift 2
                ;;
            put)
                require_value "${1}" "${2}"
                require_value "${1}" "${3}"
                put_setting "${2}" "${3}"
                shift 3
                ;;
            *)
                fail "$*"
                ;;
        esac
    done
}

##############################################################
# Process options
##############################################################

process_option() {
    local option="$1"
    case $option in
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            process_generate_options "$@"
            generate_file
            ;;
    esac
}

process_generate_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--basic)
                PARAMETERS["basic"]="${1}"
                ;;
            -c|--content)
                require_value "${1}" "${2}"
                PARAMETERS["content"]="${2}"
                shift
                ;;
            -d|--directory)
                require_value "${1}" "${2}"
                PARAMETERS["directory"]="${2}"
                shift
                ;;
            -e|--extension)
                require_value "${1}" "${2}"
                PARAMETERS["extension"]="${2}"
                shift
                ;;
            -n|--name)
                require_value "${1}" "${2}"
                PARAMETERS["filename"]="${2}"
                shift
                ;;
            -t|--time)
                PARAMETERS["datetime"]=1
                ;;
            -T|--template)
                require_value "${1}" "${2}"
                PARAMETERS["template_name"]="${2}"
                shift
                ;;
            -o|--open)
                PARAMETERS["auto_open"]=1
                if has_value "${2}"; then
                    PARAMETERS["software"]="${2}"
                    shift
                fi
                ;;
            *)
                fail "$*"
                ;;
        esac
        shift
    done
}

##############################################################
# Process the input command
##############################################################

mkf() {
    IFS=$'\x1E' read -ra new_args < <(decluster "$@")
    set -- "${new_args[@]}"

    if [ $# -eq 0 ]; then
        generate_file
        return 0
    fi
    local command="$1"
    if [[ $command == -* ]]; then
        process_option "$@"
    elif [[ -n "${HANDLERS[$command]}" ]]; then
        shift
        "${HANDLERS[$command]}" "$@"
    else
        fail "${command}" "command"
    fi
}

mkf "$@"
