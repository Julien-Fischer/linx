# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# @param $1 the path of the file to source, relative to $HOME
require_source() {
    local filepath="${1}"
    if [[ -f "${HOME}/${filepath}" ]]; then
        # shellcheck source=src/util.sh
        source "${HOME}/${filepath}"
    else
        echo "E: Could not source ${HOME}/${filepath}"
    fi
}

require_source "/linx/.linx_lib.sh"
require_source "/linx/linx.sh"
require_source ".bashrc"

##############################################################
# CONSTANTS
##############################################################

DEFAULT_PROJECT_NAME="my_project"

##############################################################
# Process
##############################################################

gproj() {
    local project_name="${DEFAULT_PROJECT_NAME}"
    local no_commit=false
    local demo=false
    local original_branch

    if [[ $# -gt 0 && $1 != -* ]]; then
        project_name="${1}"
        shift
    fi

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -n|--no-commit)
                no_commit=true
                ;;
            -d|--demo)
                demo=true
                ;;
            -h|--help)
                get_help "gproj"
                return 0
                ;;
            *)
                err "Invalid parameter: ${1}"
                get_help "gproj"
                return 1
                ;;
        esac
        shift
    done

    if ! mkdir -p "${project_name}"; then
        err "Could not create directory ${project_name}"
        return 1
    fi
    if ! cd "${project_name}"; then
        err "Could not change directory to ${project_name}"
        return 1
    fi
    if ! git init -q; then
        err "Could not initialize git repository in $(pwd)"
        return 1
    fi

    echo -e "Created $(color "${project_name}") at $(pwd)"

    original_branch="$(git branch --show-current)"

    echo ".idea" > .gitignore

    if ! $no_commit; then
        git add . && git commit -m "chore: Initial commit" -q
    fi

    if $demo; then
        for branch in "${original_branch}" branch-1 branch-2 branch-3; do
            if git rev-parse --verify "${branch}" > /dev/null 2>&1; then
                echo -e "\nswitch to $(color "${branch}" "${YELLOW_BOLD}")"
                if ! git switch "${branch}" -q; then
                    err "Failed to checkout ${branch} branch"
                fi
            else
                echo -e "create $(color "${branch}" "${YELLOW_BOLD}")"
                if ! git switch -c "${branch}" -q; then
                    err "Failed to create and checkout ${branch} branch"
                fi
            fi

            for letter in {a..z}; do
                local filename="${letter}.txt"
                if ! echo "${letter}" >> "${filename}"; then
                    err "Failed to create file ${filename}"
                fi
                if ! git add . > /dev/null; then
                    err "Failed to stage files"
                fi
                if ! git commit -m "[${branch}] ${letter}" -q; then
                    err "Failed to commit with message: '${letter}'"
                fi
            done
        done
    fi

    if ! git switch "${original_branch}" -q; then
        err "Failed to checkout original branch: '${original_branch}'"
    fi

    echo -e "\nCurrently on branch $(color "$(git branch --show-current)")"

    if git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo -e "\nHistory:"
        glo
    fi

    echo -e "\nContent:"
    la
}

gproj "$@"
