#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

if [[ -f "${HOME}"/linx/.linx_lib.sh ]]; then
    source "${HOME}"/linx/.linx_lib.sh
fi
source "${HOME}"/.bashrc


list_ports() {
    if [[ ("${1}" == "-"* && -z "${2}") ]]; then
        get_help "port"
        return 1
    fi
    local filter_type=""
    local filter_value=""

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
                get_help "port"
                return 1
                ;;
        esac
    done

    lsof -i -n | awk -v yellow="${YELLOW}" -v red="${RED}" -v none="${NC}" \
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


kill_all() {
    local subject="${1}"
    local pids=($(lsof -i | grep -i "${subject}" | awk '{print $2}' | sort -u))

    if [[ ${#pids[@]} -eq 0 ]]; then
        err "No processes found for ${subject}"
        return 1
    fi

    for pid in "${pids[@]}"; do
        echo "Attempting to kill process ${pid} for ${subject}"
        kill "${pid}"
        if [ $? -eq 0 ]; then
            echo "Killed all ${subject} processes"
        else
            err "Failed to kill all ${subject} processes"
        fi
    done
}

kill_process_by_pid() {
    local pid="${1}"
    kill_all "${pid}"
}

kill_process_by_pname() {
    local process_name="${1}"
    if [[ -z "${process_name}" ]]; then
        get_help "port"
        return 1
    fi
    kill_all "${process_name}"
}

kill_process_by_port() {
    local port="${1}"
    echo "Attempting to kill processes at port ${port}"
    kill_all "${port}"
}

kill_process() {
    if [[ $# -eq 0 || ("${1}" == "-"* && -z "${2}") ]]; then
        get_help "port"
        return 1
    elif [[ $# -eq 1 ]]; then
        kill_process_by_port "${1}"
        return 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --pid)
                kill_process_by_pid "${2}"
                return 0
                ;;
            --pname)
                kill_process_by_pname "${2}"
                return 0
                ;;
            *)
                get_help "port"
                return 1
                ;;
        esac
    done

    return 0
}


# @description
# @param $1 (optional) "kill": sends a SIGTERM signal to a process
# @flag --pid  filters the output by process id
# @flag --pname  filters the output by process name
# @flag --port  filters the output by port
# @example
#   port # list all ports
#   port --pid 2152 (optional)          # print the process with id 2152, or nothing if no process with this id is using a port
#   port --pname (optional) processName # list the ports used by the process named processName, or nothing if it does not use any port
#   port --port 8081 (optional)         # print the process using port 8081, or nothing if this port is not in us e
main() {
    if [[ $# -eq 0 ]]; then
        list_ports
        return 0
    fi
    case "${1}" in
        kill)
            shift
            kill_process "$@"
            ;;
        -*)
            list_ports "$@"
            shift
            ;;
        *)
            get_help "port"
            shift
            ;;
    esac
}

main "$@"