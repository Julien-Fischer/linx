#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

glot() {
    local substring=""
    if [[ "${1}" != -* ]]; then
        substring="${1}"
        shift
    fi
    local ascending=false
    local today_only=false
    local show_commit_count=true
    local branch_name=
    branch_name=$(git branch --show-current)

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --asc)
                ascending=true
                ;;
            -t|--today)
                today_only=true
                ;;
            -m|--minimal)
                show_commit_count=false
                ;;
            -f|--filter)
                substring="${2}"
                shift
                ;;
            -b|--branch)
                branch_name="${2}"
                if [[ -z "${branch_name}" ]]; then
                    err "--branch can not be blank"
                    return 1
                fi
                shift
                ;;
            -h|--help)
                get_help "glot"
                return 0
                ;;
            *)
                err "Unsupported option ${1}"
                get_help "glot"
                return 1
                ;;
        esac
        shift
    done

    local temp_file
    temp_file=$(mktemp)

    local params=(
        --pretty=format:"%h|%ad|%an|%ae|%s"
        --date=format:"%Y-%m-%d %H:%M:%S"
    )
    if $today_only; then
        params+=(--since "00:00:00")
    fi

    git log "${branch_name}" "${params[@]}" |
    sed '$a\' |
    while IFS='|' read -r hash date name email message; do
        if [[ "${name,,}" == "${substring,,}"* ]] || [[ "${email,,}" == "${substring,,}"* ]]; then
            echo "${hash}|${date}|${name}|${email}|${message}" >> "${temp_file}"
        fi
    done

    local sort_option="-r"
    if $ascending; then
        sort_option=""
    fi

    local count=
    count=$(wc -l < "${temp_file}")

    if $show_commit_count; then
        echo -e "$(color "$count" "${YELLOW_BOLD}") commits | ${branch_name}"
        echo ""
    fi

    local LIGHT_GRAY='\033[0;37m'
    sort -t'|' -k2 $sort_option "${temp_file}" |
    while IFS='|' read -r hash date name email message; do
        printf "${YELLOW}%-7s${NC} | ${RED}%-19s${NC} | ${CYAN_BOLD}%-20s${NC} | ${LIGHT_GRAY}%s${NC}\n" \
               "${hash}" "${date}" "${name}" "${message}"
    done

    rm "${temp_file}"
}

glot "$@"
