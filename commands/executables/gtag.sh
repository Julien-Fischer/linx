#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc

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
        get_help "gtag-create"
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
                get_help "gtag-create"
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
        get_help "gtag-delete"
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
                get_help "gtag-delete"
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
            get_help "gtag"
        ;;
        *)
            err "Unknown command: ${1}"
            get_help "gtag"
            return 1
            ;;
    esac
    return 0
}

gtag "$@"