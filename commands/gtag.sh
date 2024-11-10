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
Usage: gtag [command] [options]

Description:
  Quickly create and delete tags, both locally and on the remote

Commands:
  (no command)              List all tags, sorted by descending order.
  c, create <tagname>       Tag the latest commit with the specified tag name.
  d, delete [tagname]       Delete the latest tag or a specified tag name.

Options:
  -h, --help                Display this help message and exit.

Examples:
  gtag                      # List all tags, sorted by descending order
  gtag -h                   # Display this message and exit
EOF
)

CREATE_USAGE=$(cat <<EOF
Usage: gtag create <tagname> [-c <commit_hash>] [-p]

Description:
  Tag a commit

Command: gtag create
  Options:
    -c, --commit <hash>               Specify the hash of the commit to tag (default is the latest commit).
    -p, --push                        Push the new tag to the remote repository.
    -h, --help                        Display this help message and exit.

Examples:
  gtag c v1.0.0                       # Tag the latest commit with v1.0.0.
  gtag c v1.0.0 -p                    # Tag and push v1.0.0 to the remote repository.
  gtag c v1.0.0 -c 3804a28            # Tag commit 3804a28 with tag v1.0.0.
  gtag c v1.0.0 -c 3804a28 -p         # Tag commit 3804a28 and push tag v1.0.0 to the remote repository.
  gtag c -h                           # Display this help message and exit
EOF
)

DELETE_USAGE=$(cat <<EOF
Usage: gtag delete [<tagname>] [-p]

Description:
  When used without a positional parameter, deletes the latest tag.
  When used with a positional parameter, deletes the specified tag name.

Options:
  -h, --help                Display this help message and exit.
  -p, --push                Delete the tag both locally and on the remote repository.

Examples:
  gtag d                    # Delete the latest tag.
  gtag d -p                 # Delete the latest tag both locally and remotely.
  gtag d v1.0.0             # Delete v1.0.0.
  gtag d v1.0.0 -p          # Delete v1.0.0 both locally and remotely.
  gtag d -h                 # Display this help message and exit
EOF
)

##############################################################
# Utils
##############################################################

# @description List all tags, sorted by descending order
get_tags() {
    git tag --sort=-v:refname
#    git tag --sort=-creatordate
}

##############################################################
# Process
##############################################################

create_tag() {
    if [[ "${1}" == "-h" || "${1}" == "${--help}" ]]; then
        echo "${CREATE_USAGE}"
        return 0
    fi

    local tagname="${1}"
    shift
    local commit_hash=""
    local push=false

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -c|--commit)
                commit_hash="${2}"
                shift 2
                ;;
            -p|--push)
                push=true
                shift
                ;;
            *)
                err "Invalid parameter: ${1}"
                echo "${CREATE_USAGE}"
                return 1
                ;;
        esac
    done

    if [[ -n "${commit_hash}" ]]; then
        git tag "${tagname}" "${commit_hash}"
    else
        git tag "${tagname}"
    fi

    if $push; then
        git push origin "${tagname}"
    fi
}

delete_tag() {
    if [[ "${1}" == "-h" || "${1}" == "${--help}" ]]; then
        echo "${DELETE_USAGE}"
        return 0
    fi

    local tagname="${1}"
    shift
    local push=false

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -p|--push)
                push=true
                shift
                ;;
            *)
                err "Invalid parameter: ${1}"
                echo "${DELETE_USAGE}"
                return 1
                ;;
        esac
    done

    # If no tag name was specified, use the latest tag
    if [[ -z "${tagname}" ]]; then
        tagname=$(get_tags | head -n 1)
    fi

    if [[ -z "${tagname}" ]]; then
        err "Could not find any tag in this project"
        return 1
    fi

    git tag -d "${tagname}"
    if $push; then
        git push --delete origin "${tagname}"
    fi
}

gtag() {
    case $1 in
        "")
            get_tags
            ;;
        c|create)
            shift
            create_tag "$@"
            ;;
        d|delete)
            shift
            delete_tag "$@"
            ;;
        -h|--help)
            echo "${USAGE}"
        ;;
        *)
            err "Unknown command: ${1}"
            echo "${USAGE}"
            return 1
            ;;
    esac
    return 0
}

gtag "$@"