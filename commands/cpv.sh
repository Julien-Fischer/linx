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

source="${1}"
target="${2:-.}"
quiet=false

##############################################################
# Doc
##############################################################

USAGE=$(cat <<EOF
Usage: cpv [OPTIONS] SOURCE DESTINATION

Description:
  Copy files and directories from SOURCE to DESTINATION with a visual progress bar.

Positional parameters:
  $1            (Source) The file or directory to copy. This can be a single file, a directory, or a wildcard pattern.
  $2            (Target) The destination where the files or directories will be copied. This should be a valid path.

Options:
  -h, --help    Display this help message and exit
  -q, --quiet   Mute outputs

Return Values:
  0             If the operation completed successfully.
  1+            If an error occurred during the operation.

Examples:
  cpv myfile dirA            # Copies myfile into 'dirA'.
  cpv projects dirA          # Copies the 'projects' directory into 'dirA'.
  cpv projects/ dirA         # Copies all files and directories from 'projects' into 'dirA'.
EOF
)

##############################################################
# Process
##############################################################

parse_params() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -q|--quiet)
                quiet=true
                ;;
            -h|--help)
                echo "${USAGE}"
                return 0
                ;;
            *)
                err "Unknown parameter ${1}"
                echo "${USAGE}"
                return 1
                ;;
        esac
        shift
    done
}

copy_file() {
    if [[ ! -f "${source}" ]]; then
        return 1
    fi
    sudo cp "${source}" "${target}"
    ! $quiet && echo "Backed up [file] ${source} at ${target}"
    return 0
}

copy_dir() {
    if [[ ! -d "${source}" ]]; then
        return 1
    fi
    sudo rsync "${source}" "${target}" -ah --info=progress2 --partial
    ! $quiet && echo "Backed up [dir] ${source} at ${target}"
}

cpv() {
    parse_params "$@"
    if ! copy_file && ! copy_dir; then
        ! $quiet && err "Could not find any file or directory at ${source}"
        return 1
    fi
    return 0
}

cpv "$@"