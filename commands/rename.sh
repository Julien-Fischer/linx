#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Source linx
if [ -f "${HOME}"/linx/.linx_lib.sh ]; then
    source "${HOME}"/linx/.linx_lib.sh
fi

##############################################################
# Input
##############################################################

root_dir="."
naming_scheme=""
sort_rule="n"
recursive=false
dry_run=false
execute=false
ignore_extension=false

##############################################################
# Computed
##############################################################

files=

##############################################################
# Utils
##############################################################

show_help() {
    get_help 'rename'
}

append_creation_date() {
    local file="${1}"
    echo "$(date -d @"$(stat --format='%W' "$file")" +"%Y-%m-%d")_"
}

append_last_modified_date() {
    local file="${1}"
    echo "$(date -d @"$(stat --format='%Y' "$file")" +"%Y-%m-%d")_"
}

append_file_name() {
    local filename="${1}"
    echo "${filename}_"
}

append_dir_name() {
    local containing_dir_name="${1}"
    echo "${containing_dir_name}_"
}

append_current_date() {
    echo "$(date '+%Y-%m-%d')_"
}

append_auto_incremented_integer() {
    local count="${1}"
    echo "$(printf "%03d" "${count}")_"
}

sort_by_creation_date() {
    echo "$files" | xargs stat --format='%W %n' | sort | cut -d' ' -f2-
}

sort_by_modified_date() {
    echo "$files" | xargs stat --format='%Y %n' | sort | cut -d' ' -f2-
}

sort_by_name() {
    echo "$files" | sort
}

sort_by_type() {
    echo "$files" | xargs file --mime-type | sort -k2 | cut -d':' -f1
}

sort_by_size() {
    echo "$files" | xargs du -b | sort -n | cut -f2-
}

##############################################################
# Parsing
##############################################################

parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --as) naming_scheme="$2"; shift ;;
            --sort) sort_rule="$2"; shift ;;
            -i|--ignore-extension) ignore_extension=true ;;
            -r|--recursive) recursive=true ;;
            --mode)
              case $2 in
                dry-run) dry_run=true ;;
                execute) execute=true ;;
                interactive) dry_run=false; execute=false ;;
                *) err "Invalid mode: $2"; show_help; exit 1 ;;
              esac
              shift ;;
            -h|--help) get_help 'rename'; exit 0 ;;
            *) root_dir="$1" ;;
        esac
        shift
    done

    # Validate input
    if [[ -z "$naming_scheme" ]]; then
        err "Naming scheme (--as) is required."
        show_help
        exit 1
    fi
}

fetch_files() {
    if $recursive; then
        files=$(find "$root_dir" -type f)
    else
        files=$(find "$root_dir" -maxdepth 1 -type f)
    fi

    files=$(get_sorted_files "$sort_rule")
    return $?
}

get_sorted_files() {
    local sort_rule="$1"
    local sorted_files

    case $sort_rule in
        c) sorted_files=$(sort_by_creation_date) ;;
        m) sorted_files=$(sort_by_modified_date) ;;
        n) sorted_files=$(sort_by_name) ;;
        t) sorted_files=$(sort_by_type) ;;
        s) sorted_files=$(sort_by_size) ;;
        *) err "rename: Unknown sort option: $1" && exit 1 ;;
    esac

    echo "$sorted_files"
}

##############################################################
# Processing
##############################################################

compute_new_name() {
    local file="${1}"
    local containing_dir_path="${2}"
    local containing_dir_name="${3}"
    local count="${4}"
    local filename="${basename%.*}"
    local new_name=""

    for CHAR in $(echo "$naming_scheme" | grep -o .); do
        case $CHAR in
            c|--created-date)   new_name+=$(append_creation_date "${file}") ;;
            f|--filename)       new_name+=$(append_file_name "${filename}") ;;
            m|--modified-date)  new_name+=$(append_last_modified_date "${file}") ;;
            t|--current-date)   new_name+=$(append_current_date) ;;
            i|--integer)        new_name+=$(append_auto_incremented_integer "${count}") ;;
            d|--dirname)        new_name+=$(append_dir_name "${containing_dir_name}") ;;
        esac
    done

    new_name="${new_name%_}"
    if ! $ignore_extension; then
        local extension="${basename##*.}"
        if [[ "${filename}" = "${extension}" ]]; then
            extension=''
        fi
        new_name+="${extension:+.}${extension}"
    fi

    echo "${new_name}"
}

rename_files() {
    local count=1
    for file in $files; do
        local basename=$(basename "${file}")
        local containing_dir_path=$(dirname "$(resolve_directory_path "${file}")")
        local containing_dir_name=$(basename "${containing_dir_path}")

        local new_name=$(compute_new_name "${file}" "${containing_dir_path}" "${containing_dir_name}" "${count}")

        if $dry_run; then
            echo "[Dry Run] ${basename} -> ${new_name}"
        elif $execute; then
            mv "${file}" "${containing_dir_path}/${new_name}"
            echo "Renamed: ${basename} -> ${new_name}"
        fi

        count=$((count + 1))
    done
}

# client code

parse_arguments "$@"

if fetch_files; then
    if $dry_run; then
        rename_files
    elif $execute; then
        rename_files
    else
        dry_run=true
        rename_files
        if confirm "Renaming" "Proceed with the renaming?"; then
            dry_run=false
            execute=true
            rename_files
        fi
    fi
fi
