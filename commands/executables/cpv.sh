#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

trap 'linx_spinner_stop' EXIT

##############################################################
# Input parameters
##############################################################

source=
target=
include_code=false
quiet=false
spin=false

##############################################################
# Process
##############################################################

parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -C|--code)
                include_code=true
                ;;
            -q|--quiet)
                quiet=true
                ;;
            -s|--spin)
                spin=true
                ;;
            *)
                err "Unknown parameter '${1}'"
                get_help "cpv"
                return 1
                ;;
        esac
        shift
    done
}

parse_params() {
    if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
        get_help "cpv"
        return 0
    fi
    source="${1}"
    target="${2:-.}"
    shift 2
    parse_options "$@"
}

copy_file() {
    if [[ ! -f "${source}" ]]; then
        return 1
    fi
    local options=(-avh --info=progress2 --partial)
    if ! $include_code; then
        options+=(--exclude="target" --exclude="node_modules")
    fi
    if ! cp "${source}" "${target}"; then
        err "Could not copy [file] ${source} to ${target}"
        return 1
    fi
    ! $quiet && echo -e "Copied $(color [file] "${YELLOW}") $(color "${source}") to $(color "${target}" "${GREEN_BOLD}")"
    return 0
}

copy_dir() {
    if [[ ! -d "${source}" ]]; then
        return 1
    fi
    local options=(-avh --info=progress2 --partial)
    if ! $include_code; then
        options+=(--exclude="target" --exclude="node_modules")
    fi
    if $spin; then
        linx_spinner_start
        if ! rsync "${options[@]}" "${source}" "${target}" > /dev/null; then
            err "Could not copy [dir] ${source} to ${target}"
            return 1
        fi
        linx_spinner_stop
    else
        if ! rsync "${options[@]}" "${source}" "${target}"; then
            err "Could not copy [dir] ${source} to ${target}"
            return 1
        fi
    fi
    ! $quiet && echo -e "Copied $(color [dir] "${YELLOW}") $(color "${source}") to $(color "${target}" "${GREEN_BOLD}")"
}

cpv() {
    if ! parse_params "$@"; then
        return 1
    fi

    if [[ -f "${source}" ]]; then
        copy_file
        return $?
    elif [[ -d "${source}" ]]; then
        mkdir -p "${target}"
        copy_dir
        return $?
    fi

    return 1
}

cpv "$@"
