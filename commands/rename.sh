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

DIR="."
NAMING_SCHEME=""
SORT_RULE="n"
RECURSIVE=false
DRY_RUN=false
ignore_extension=false

##############################################################
# Computed
##############################################################

files=

##############################################################
# Utils
##############################################################

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

##############################################################
# Parsing
##############################################################

parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
      case $1 in
        --as) NAMING_SCHEME="$2"; shift ;;
        --sort) SORT_RULE="$2"; shift ;;
        -i|--ignore-extension) ignore_extension=true ;;
        -r|--recursive) RECURSIVE=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) get_help 'rename'; exit 0 ;;
        *) DIR="$1" ;;
      esac
      shift
    done

    # Validate input
    if [[ -z "$NAMING_SCHEME" ]]; then
        err "Naming scheme (--as) is required."
        show_help
        exit 1
    fi
}

fetch_files() {
    if $RECURSIVE; then
        files=$(find "$DIR" -type f)
    else
        files=$(find "$DIR" -maxdepth 1 -type f)
    fi

    files=$(get_sorted_files "$SORT_RULE")
    return 0
}

get_sorted_files() {
  local sort_rule="$1"
  case $sort_rule in
    c) echo "$files" | xargs stat --format='%W %n' | sort | cut -d' ' -f2- ;; # Creation date
    m) echo "$files" | xargs stat --format='%Y %n' | sort | cut -d' ' -f2- ;; # Modified date
    n) echo "$files" | sort ;;                                                # Name
    t) echo "$files" | xargs file --mime-type | sort -k2 | cut -d':' -f1 ;;   # Type
    s) echo "$files" | xargs du -b | sort -n | cut -f2- ;;                    # Size
    *) echo "$files" ;;                                                       # No sorting
  esac
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

    for CHAR in $(echo "$NAMING_SCHEME" | grep -o .); do
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

        if $DRY_RUN; then
            echo "[Dry Run] ${basename} -> ${new_name}"
        else
            mv "${file}" "${containing_dir_path}/${new_name}"
            echo "Renamed: ${file} -> ${new_name}"
        fi

        count=$((count + 1))
    done
}

# client code

parse_arguments "$@"

if fetch_files; then
    rename_files
fi