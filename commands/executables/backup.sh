#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

##############################################################
# Process
##############################################################

backup() {
    IFS=$'\x1E' read -ra new_args < <(decluster "$@")
    set -- "${new_args[@]}"

    if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
        get_help "backup"
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
        get_help "backup"
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
                get_help "backup"
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
        local command="${COMMANDS_DIR}/backup '${src}' -t -d ${absolute_target_dir}"
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
        if [[ -d "${source}" ]]; then
            rm -rf "${source:?}"/{*,.*}
        elif [[ -f "${source}" ]]; then
            printf '' > "${src}"
        else
            err "${source} is neither a file nor a directory"
            return 1
        fi
    fi
}

backup "$@"