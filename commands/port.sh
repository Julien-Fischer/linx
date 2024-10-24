#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/.linx_lib.sh ]]; then
    source "${HOME}"/.linx_lib.sh
fi
source "${HOME}"/.bashrc

USAGE="Usage: port [--pid <process_id>] [--pname <process_name>] [--port <port_number>]"

# @description
# @flag --pid  filters the output by process id
# @flag --pname  filters the output by process name
# @flag --port  filters the output by port
# @example
#   port # list all ports
#   port --pid 2152 (optional)          # print the process with id 2152, or nothing if no process with this id is using a port
#   port --pname (optional) processName # list the ports used by the process named processName, or nothing if it does not use any port
#   port --port 8081 (optional)         # print the process using port 8081, or nothing if this port is not in us e
port() {
    local filter_type=""
    local filter_value=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pid)
                filter_type="pid"
                filter_value="$2"
                shift 2
                ;;
            --pname)
                filter_type="pname"
                filter_value="$2"
                shift 2
                ;;
            --port)
                filter_type="port"
                filter_value="$2"
                shift 2
                ;;
            *)
                echo "${USAGE}"
                return 1
                ;;
        esac
    done

    yellow="\033[1;33m"
    red="\033[1;31m"
    none="\033[0m"

    lsof -i -n | awk -v yellow="$yellow" -v red="$red" -v none="$none" \
                      -v filter_type="$filter_type" -v filter_value="$filter_value" '
    BEGIN {
        OFS = " "
    }
    NR==1 {
        printf "\033[1;34m%-20s %-10s %-10s %-10s %-10s %-42s %-15s\033[0m\n", $1, $2, $3, $4, $5, "NAME", "STATUS"
        next
    }
    {
        if (filter_type == "port") {
            split($9, port_parts, ":")
            port = port_parts[length(port_parts)]
        }

        if ((filter_type == "") ||
            (filter_type == "pid" && $2 == filter_value) ||
            (filter_type == "pname" && $1 == filter_value) ||
            (filter_type == "port" && port == filter_value)) {

            color_pid = "\033[1;32m" $2 "\033[0m"

            split($9, parts, "->")
            if (length(parts) == 2) {
                split(parts[1], left, ":")
                split(parts[2], right, ":")
                color_port = yellow left[1] ":" left[2] none "->" red right[1] none ":" right[2]
            } else {
                color_port = yellow $9 none
            }

            status = $NF
            color_status = (status ~ /LISTEN/) ? "\033[1;35m" status "\033[0m" : (status ~ /ESTABLISHED/) ? "\033[1;36m" status "\033[0m" : status

            printf "%-20s %-20s %-10s %-10s %-10s %-65s %-15s\n", $1, color_pid, $3, $4, $5, color_port, color_status
        }
    }'
}

port "$@"