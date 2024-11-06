#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

# @description Backup the element identified by the specified path. If the element to backup is
#              a directory, copy it recursively
# @param $1 the file or directory to backup
# @param $2 (optional) an arbitrary string to use as a prefix for the backup name
# @flag -e,--no-extension if the extension must be dropped (requires that at least -t or $2 are specified)
# @flag -n,--no-name if the filename must be dropped (requires that at least -t is specified)
# @flag -q,--quiet if this operation should mute outputs
# @flag -r,--reverse if the prefix should be used as a suffix, and the timestamp as a prefix
# @flag -t,--time if the backup name should be timestamped
# @flag -c,--compact if the date should have no separator (e.g. 2024-10-21_23-28-41 -> 20241021232841) (requires
#          that -t is specified)
# @return 0 if the operation completed successfully; 1 otherwise
# @example
#   backup mydir          # create a copy of mydir, named mydir.bak
#   backup mydir -q dirA  # backup mydir, quietly
#   backup myfile -t      # create a copy of myfile with a timestamp as suffix (e.g. myfile_2024-09-03_09-53-42.bak
#   backup myfile -t -r   # create a copy of myfile with a timestamp as prefix (e.g. 2024-09-03_09-53-42_myfile.bak
#   backup mydir backup   # create a copy of myfile with backup as a prefix: backup_mydir
backup() {
    # shellcheck disable=SC2046
    set -- $(decluster "$@")
    local USAGE="Usage: backup <filepath|dirpath> [[prefix]] [[-cenqrt]]"
    local SEPARATOR="_"
    local source=${1%/} # trim slash
    local prefix="${2}"
    local quiet=1
    local use_time=1
    local time=""
    local reverse=1
    local drop_name=1
    local compact=1
    local drop_extension=false
    local name=$(basename "${source}")
    local path=$(dirname "${source}")
    local complete_name=
    local target=

    if [[ -z "${source}" ]]; then
        err "No source specified."
        echo "${USAGE}"
        return 1
    fi

    if [[ "${prefix}" == "-"* ]]; then
        prefix=''
    fi

    shift
    if [[ -n "${prefix}" ]]; then
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "${USAGE}"
                return 0
                ;;
            -e|--no-extension)
                drop_extension=true
                ;;
            -t|--time)
                use_time=0
                ;;
            -r|--reverse)
                reverse=0
                ;;
            -q|--quiet)
                quiet=0
                ;;
            -n|--no-name)
                drop_name=0
                ;;
            -c|--compact)
                compact=0
                ;;
            *)
                err "Unknown parameter ${1}"
                echo "${USAGE}"
                return 1
                ;;
        esac
        shift
    done

    if [[ $use_time -eq 0 ]]; then
        if [[ $compact -eq 0 ]]; then
            time=$(timestamp -c)
        else
            time=$(timestamp -s - _ -)
        fi
    fi

    local sep_a=${time:+$SEPARATOR}
    local sep_b=${prefix:+$SEPARATOR}

    if [[ $drop_name -eq 0 ]]; then
        if [[ $use_time -ne 0 && "${prefix}" -ne 0 ]]; then
            err "-n requires that at least -t or \$2 are specified"
            return 1
        else
            name=""
            sep_a=""
            if [[ $use_time -eq 1 ]]; then
                sep_b=""
            fi
        fi
    fi

    if [[ $reverse -ne 0 ]]; then
        complete_name="${time}${sep_a}${name}${sep_b}${prefix}"
    else
        complete_name="${prefix}${sep_b}${name}${sep_a}${time}"
    fi

    if ! $drop_extension; then
        if [[ $use_time -eq 0 || $drop_name -ne 0 ]]; then
            complete_name+=".bak"
        else
            err "-e requires at least that -t or a filename is specified."
            return 1
        fi
    fi
    target="${path}/${complete_name}"

    if [[ -f "${source}" ]]; then
        sudo cp "${source}" "${target}"
        [[ $quiet -ne 0 ]] && echo "Backed up [file] ${source} at ${target}"
        return 0
    fi
    if [[ -d "${source}" ]]; then
        sudo rsync "${source}" "${target}" -ah --info=progress2 --partial
        [[ $quiet -ne 0 ]] && echo "Backed up [dir] ${source} at ${target}"
        return 0
    fi
    [[ $quiet -ne 0 ]] && err "Could not find any file or directory at ${source}"
    return 1
}

backup "$@"