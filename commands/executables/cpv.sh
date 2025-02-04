#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

##############################################################
# Input parameters
##############################################################

source=
target=
quiet=false

##############################################################
# Process
##############################################################

parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -q|--quiet)
                quiet=true
                ;;
            *)
                err "Unknown parameter ${1}"
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
    cp "${source}" "${target}"
    ! $quiet && echo "Copied [file] ${source} at ${target}"
    return 0
}

copy_dir() {
    if [[ ! -d "${source}" ]]; then
        return 1
    fi
    rsync "${source}/" "${target}" -ah --info=progress2 --partial
    ! $quiet && echo "Copied [dir] ${source} at ${target}"
}

cpv() {
    parse_params "$@"
    if copy_file || copy_dir; then
        return 0
    fi
    ! $quiet && err "Could not find any file or directory at ${source}"
    return 1
}

cpv "$@"