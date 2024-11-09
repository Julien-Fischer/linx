#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

USAGE=$(cat <<EOF
Usage: timestamp [OPTIONS]

Outputs the current datetime, with desired format (if specified).
Default format: YYYY-MM-DD hh:mm:s

Options:
  -i, --iso        Output in ISO 8601 format (YYYY-MM-DDThh:mm:ss)
  -b, --basic      Output in Basic ISO 8601 Format format without separators (YYYYMMDDhhmmss)
  -r, --readable   Output in a more readable format (YYYY-MM-DD_hh:mm:ss)
  -s, --separators Specify custom separators for date/time components
                   Up to 3 separators can be provided:
                   1st: Date separator (default: '-')
                   2nd: Date-time separator (default: ' ')
                   3rd: Time separator (default: ':')
  -h, --help       Show this help message and exit

Examples:
  # assuming the current datetime is 2024-11-03 09:34:56
  timestamp                # 2024-11-03 09:34:56
  timestamp -i             # 2024-11-03T09:34:56
  timestamp -r             # 2024-11-03_09:34:56
  timestamp -b             # 20241103093456
  timestamp -s '/'         # 2024/11/03 09:34:56
  timestamp -s '/' '_'     # 2024/11/03_09:34:56
  timestamp -s '/' '_' '-' # 2024/11/03_09-34-56
EOF
)

# @description Outputs the current datetime, with desired format (if specified).
#              Default format: YYYY-MM-DD hh:mm:s
# @option -i, --iso
# @option -b, --basic
# @option -r, --readable
# @option -s, --separators '/' '_' ':'
# @example
#   # assuming the current datetime is 2024-11-03 09:34:56
#   timestamp                # 2024-11-03 09:34:56
#   timestamp -i,            # 2024-11-03T09:34:56
#   timestamp -r,            # 2024-11-03_09:34:56
#   timestamp -b,            # 20241103093456
#   timestamp -s '/'         # 2024/11/03 09:34:56
#   timestamp -s '/' '_'     # 2024/11/03_09:34:56
#   timestamp -s '/' '_' '-' # 2024/11/03_09-34-56
# shellcheck disable=SC2120
timestamp() {
    local format="%Y-%m-%d %H:%M:%S"
    local date_sep="-"
    local time_sep=":"
    local datetime_sep=" "

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "${USAGE}"
                return 0
                ;;
            -i|--iso)
                format="%Y-%m-%dT%H:%M:%S"
                ;;
            -b|--basic)
                format="%Y%m%d%H%M%S"
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