#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

##############################################################
# Doc
##############################################################

USAGE=$(cat <<EOF
Usage: backup <file_or_directory> [prefix] [options]

Backup the element identified by the specified path. If the element to backup is
a directory, copy it recursively.

Arguments:
  <file_or_directory>     The file or directory to backup
  [prefix]                (Optional) An arbitrary string to use as a prefix for the backup name

Options:
  -d, --destination       The absolute path of the directory where the backup must be created
  -h, --help              Show this message and exit
  -q, --quiet             Mute outputs
  -b, --basic             Use compact date format without separators (requires -t)

Tile options:
  -r, --reverse           Use the prefix as a suffix, and the timestamp as a prefix
  -t, --time              Add a timestamp to the backup name
  -o, --only-compact      If the filename must be a simple compact date. This is equivalent to backup [filename] -bt --no-extension --no-name
  --no-extension          Drop the file extension (requires that at least -t or prefix are specified)
  --no-name               Drop the filename (requires that at least -t is specified)

Cron options:
  -c, --cron              Periodically backup the source using a cron expression
  -v, --verbose           Log standard output for debugging when used with --cron
  -e, --erase             Clear the original file once it is backed up. Useful for log management
  -i, --instantly         Backup the source before scheduling a recurring backup

Examples:
  backup mydir                                    # Create a copy of mydir, named mydir.bak
  backup mydir -q dirA                            # Backup mydir, quietly
  backup myfile -t                                # Create a copy of myfile with a timestamp as suffix
                                                  # (e.g., myfile_2024-09-03_09-53-42.bak)
  backup myfile -t -r                             # Create a copy of myfile with a timestamp as prefix
                                                  # (e.g., 2024-09-03_09-53-42_myfile.bak)
  backup mydir backup                             # Create a copy of mydir with 'backup' as a prefix
                                                  # (e.g., backup_mydir)
  backup mydir -bt --no-extension --no-name       # Create a copy of mydir using the current compact date as the file name
                                                  # (e.g., 20241106215624)
  backup mydir -o                                 # Shorthand for: backup mydir -bt --no-extension --no-name
  backup mydir -c '0 0 * * 0'                     # Backup mydir every sunday at midnight
  backup mydir -c '0 0 * * 0' -d /path/to/dir     # Backup mydir every sunday at midnight in /path/to/dir
  backup mydir -c '0 0 * * 0' -d /path/to/dir -v  # Backup mydir with verbose log level
  backup mydir -c '0 0 * * *' -d /path/to/dir -e  # Backup mydir every day and clear its content
  backup mydir -c '0 0 * * *' -d /path/to/dir -i  # Backup mydir right now, then every day
EOF
)

##############################################################
# Process
##############################################################

backup() {
    IFS=$'\x1E' read -ra new_args < <(decluster "$@")
    set -- "${new_args[@]}"

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
    local verbose=false
    local erase=false
    local instantly=false
    local cron_expression=
    local name=$(basename "${source}")
    local source_dir=$(dirname "${source}")
    local target_dir="${source_dir}"
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
                use_time=true
                shift
                ;;
            -d|--destination)
                target_dir="${2}"
                shift
                ;;
            -e|--erase)
                erase=true
                ;;
            -i|--instantly)
                instantly=true
                ;;
            --no-extension)
                drop_extension=true
                ;;
            --no-name)
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
            -v|--verbose)
                verbose=true
                ;;
            *)
                err "Unknown parameter ${1}"
                echo "${USAGE}"
                return 1
                ;;
        esac
        shift
    done

    # if cron job, just schedule backup and return

    local absolute_source_dir=$(realpath "${source_dir}")
    local absolute_target_dir=$(realpath "${target_dir}")
    src="${absolute_source_dir}/${name}"

    if [[ -n "${cron_expression}" ]]; then
        if [[ ! -f "${src}" && ! -d "${src}" ]]; then
            ! $quiet && err "Could not find any file or directory at ${src}"
            return 1
        fi
        local command="/usr/local/bin/backup '${src}' -t -d ${absolute_target_dir}"
        if cron_exists "${cron_expression}" "${command}"; then
            err "Cron job already exists"
            return 1
        else
            local args='--quiet'
            local display_mode=""
            if $verbose; then
                args+=' --verbose'
                display_mode="with verbose mode"
            fi
            if $erase; then
                args+=' --erase'
            fi
            # shellcheck disable=SC2086
            add_cron "${cron_expression}" "${command}" $args
            echo -e "$(color "${name}" "${GREEN}") backup scheduled: ${cron_expression} ${display_mode}."
            echo -e "Command: $(color "${command}" "${GREEN}")"
            echo -e "Params: $(color "${args}" "${YELLOW}")"
            if ! $instantly; then
                return 0
            fi
        fi
    fi

    # otherwise, backup the source now

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

    local target_path="${absolute_target_dir}/${complete_name}"
    if ! cpv "${src}" "${target_path}"; then
        err "Could not copy ${src} to ${target_path}"
        return 1
    fi

    if $erase; then
        printf '' > "${src}"
    fi
}

backup "$@"