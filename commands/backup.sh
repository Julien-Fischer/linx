#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

# doc

USAGE=$(cat <<EOF
Usage: backup <file_or_directory> [prefix] [options]

Backup the element identified by the specified path. If the element to backup is
a directory, copy it recursively.

Arguments:
  <file_or_directory>     The file or directory to backup
  [prefix]                (Optional) An arbitrary string to use as a prefix for the backup name

Options:
  -b, --basic             Use compact date format without separators (requires -t)
  -c, --cron              Periodically backup the source using the specified cron expression
  -d, --destination       The absolute path of the directory where the backup must be created
  -e, --no-extension      Drop the file extension (requires that at least -t or prefix are specified)
  -h, --help              Show this message and exit
  -n, --no-name           Drop the filename (requires that at least -t is specified)
  -q, --quiet             Mute outputs
  -r, --reverse           Use the prefix as a suffix, and the timestamp as a prefix
  -t, --time              Add a timestamp to the backup name
  -o, --only-compact      if the filename must be a simple compact date. This is equivalent to backup [filename] -ecnt

Examples:
  backup mydir                                # Create a copy of mydir, named mydir.bak
  backup mydir -q dirA                        # Backup mydir, quietly
  backup myfile -t                            # Create a copy of myfile with a timestamp as suffix
                                              # (e.g., myfile_2024-09-03_09-53-42.bak)
  backup myfile -t -r                         # Create a copy of myfile with a timestamp as prefix
                                              # (e.g., 2024-09-03_09-53-42_myfile.bak)
  backup mydir backup                         # Create a copy of mydir with 'backup' as a prefix
                                              # (e.g., backup_mydir)
  backup mydir -ecnqrt                        # Create a copy of mydir using the current compact date as the file name
                                              # (e.g., 20241106215624)
  backup mydir -o                             # Shorthand for backup mydir -ecnt
  backup mydir -c '0 0 * * 0'                 # Backup mydir every sunday at midnight
  backup mydir -c '0 0 * * 0' -d /path/to/dir # Backup mydir every sunday at midnight in /path/to/dir
EOF
)

backup() {
    # shellcheck disable=SC2046
    set -- $(decluster "$@")

    # Check for help flag first
    if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
        echo "${USAGE}"
        return 0
    fi

    local SEPARATOR="_"
    local source=${1%/} # trim slash
    local prefix="${2}"
    local time=""
    local quiet=false
    local use_time=false
    local reverse=false
    local drop_name=false
    local compact=false
    local drop_extension=false
    local cron_expression=
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
            -b|--basic)
                compact=true
                ;;
            -c|--cron)
                cron_expression="${2}"
                shift
                ;;
            -d|--destination)
                path="${2}"
                shift
                ;;
            -e|--no-extension)
                drop_extension=true
                ;;
            -n|--no-name)
                drop_name=true
                ;;
            -q|--quiet)
                quiet=true
                ;;
            -r|--reverse)
                reverse=true
                ;;
            -t|--time)
                use_time=true
                ;;
            -o|--only-compact)
                drop_extension=true
                use_time=true
                drop_name=true
                compact=true
                ;;
            *)
                err "Unknown parameter ${1}"
                echo "${USAGE}"
                return 1
                ;;
        esac
        shift
    done

    if $use_time; then
        if $compact; then
            time=$(timestamp -b)
        else
            time=$(timestamp -s - _ -)
        fi
    fi

    local sep_a=${time:+$SEPARATOR}
    local sep_b=${prefix:+$SEPARATOR}

    if $drop_name; then
        if ! $use_time && ! $prefix; then
            err "-n requires that at least -t or \$2 are specified"
            return 1
        else
            name=""
            sep_a=""
            if ! $use_time; then
                sep_b=""
            fi
        fi
    fi

    if ! $reverse; then
        complete_name="${time}${sep_a}${name}${sep_b}${prefix}"
    else
        complete_name="${prefix}${sep_b}${name}${sep_a}${time}"
    fi

    if ! $drop_extension; then
        if $use_time || ! $drop_name; then
            complete_name+=".bak"
        else
            ! $quiet && err "-e requires at least that -t or a filename is specified."
            return 1
        fi
    fi
    target="${path}/${complete_name}"

    if [[ -n "${cron_expression}" ]]; then
        local command="backup '${source}' '${target}' -t"
        if cron_exists "${cron_expression}" "${command}"; then
            err "E: Cron job already exists"
            return 1
        else
#            local temp_file=$(mktemp)
#            crontab -l > "${temp_file}"
#            echo "${cron_expression} ${command}" >> "${temp_file}"
#            crontab "${temp_file}"
#            rm "${temp_file}"
            (crontab -l 2>/dev/null; echo "${cron_expression} ${command}") | crontab -
            echo "Cron job created: ${cron_expression} ${command}"
            return 0
        fi
    fi
    if [[ -f "${source}" ]]; then
        sudo cp "${source}" "${target}"
        ! $quiet && echo "Backed up [file] ${source} at ${target}"
        return 0
    fi
    if [[ -d "${source}" ]]; then
        sudo rsync "${source}" "${target}" -ah --info=progress2 --partial
        ! $quiet && echo "Backed up [dir] ${source} at ${target}"
        return 0
    fi
    ! $quiet && err "Could not find any file or directory at ${source}"
    return 1
}

backup "$@"