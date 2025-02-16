#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

##############################################################
# Constants
##############################################################

LOCAL_COMMIT_SYMBOL="X"
PUSHED_COMMIT_SYMBOL="-"

##############################################################
# Helper
##############################################################

get_status_color() {
    case $1 in
        "${PUSHED_COMMIT_SYMBOL}")
            echo "${GREEN}";
            ;;
        "${LOCAL_COMMIT_SYMBOL}")
            echo "${RED_BOLD}";
            ;;
        *)
            err "Unknown status ${1}: must be one of (${PUSHED_COMMIT_SYMBOL}, ${LOCAL_COMMIT_SYMBOL})"
            ;;
    esac
}

##############################################################
# Process
##############################################################

glot() {
    if ! is_git_repo; then
        return 1
    fi
    local substring=""
    if [[ "${1}" != -* ]]; then
        substring="${1}"
        shift
    fi
    local ascending=false
    local today_only=false
    local show_commit_count=true
    local branch_name
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
        --pretty=format:"%H|%h|%ad|%an|%ae|%s"
        --date=format:"%Y-%m-%d %H:%M:%S"
    )
    if $today_only; then
        params+=(--since "00:00:00")
    fi

    branch_name=$(git_current_branch)
    remote_tracking_branch="$(git_current_branch --remote)"

    if [[ -z "${remote_tracking_branch}" ]]; then
        all_local=true
    else
        all_local=false
        local_commits=$(git rev-list "${remote_tracking_branch}".."${branch_name}")
    fi

    git log "${branch_name}" "${params[@]}" |
    sed '$a\' |
    while IFS='|' read -r full_hash hash date name email message; do
        if [[ "${name,,}" == "${substring,,}"* ]] || [[ "${email,,}" == "${substring,,}"* ]]; then
            if $all_local || [[ $local_commits == *"$full_hash"* ]]; then
                status="${LOCAL_COMMIT_SYMBOL}"
            else
                status="${PUSHED_COMMIT_SYMBOL}"
            fi
            echo "${status}|${hash}|${date}|${name}|${email}|${message}" >> "${temp_file}"
        fi
    done

    local sort_option="-r"
    if $ascending; then
        sort_option=""
    fi

    commit_count=$(wc -l < "${temp_file}")

    if $show_commit_count; then
        echo -e "$(color "${commit_count}" "${YELLOW_BOLD}") commits | ${branch_name}"
        echo ""
    fi

    sort -t'|' -k3 $sort_option "${temp_file}" |
    while IFS='|' read -r status hash date name email message; do
        printf "$(get_status_color "${status}")%-1s${NC} | ${YELLOW}%-7s${NC} | ${RED}%-19s${NC} | ${CYAN_BOLD}%-20s${NC} | ${LIGHT_GRAY}%s${NC}\n" \
               "${status}" "${hash}" "${date}" "${name}" "${message}"
    done

    rm "${temp_file}"
}

glot "$@"
