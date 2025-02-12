#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# Source linx
if [ -f "${HOME}"/linx/.linx_lib.sh ]; then
    source "${HOME}"/linx/.linx_lib.sh
fi

timestamp() {
    local format="%Y-%m-%d %H:%M:%S"
    local date_sep="-"
    local time_sep=":"
    local datetime_sep=" "

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -b|--basic)
                format="%Y%m%d%H%M%S"
                ;;
            -h|--help)
                get_help "timestamp"
                return 0
                ;;
            -i|--iso)
                format="%Y-%m-%dT%H:%M:%S"
                ;;
            -r|--readable)
                datetime_sep="_"
                format="%Y-%m-%d_%H:%M:%S"
                ;;
            -s|--separators)
                if [[ "$#" -lt 2 ]]; then
                    err "-s option requires at least one separator"
                    return 1
                fi
                shift
                date_sep="$1"
                datetime_sep="${2:-$datetime_sep}"
                time_sep="${3:-$time_sep}"
                format="%Y${date_sep}%m${date_sep}%d${datetime_sep}%H${time_sep}%M${time_sep}%S"
                shift 2
                ;;
            *)
                err "Unknown option ${1}"
                return 1
                ;;
        esac
        shift
    done

    date +"$format"
}

timestamp "$@"
