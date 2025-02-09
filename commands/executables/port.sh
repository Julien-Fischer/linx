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

kill_process_by_pid() {
    local pid="${1}"
    local temp_file file_descriptor_count stripped_pid trimmed_pid

    trap 'rm -f "$temp_file"' EXIT
    temp_file=$(mktemp)

    stripped_pid=$(echo "${pid}" | sed 's/\x1b\[[0-9;]*m//g')
    trimmed_pid="$(trim "${stripped_pid}")"
    port | awk -v pid="${trimmed_pid}" '$2 ~ pid {print $0}' > "${temp_file}"

    file_descriptor_count=$(wc -l < "${temp_file}" | sort -u)

    if [[ $file_descriptor_count -eq 0 ]]; then
        err "Could not find any process with pid ${pid}"
        return 1
    elif [[ $file_descriptor_count -gt 1 ]]; then
        echo ""
        echo -e "Process ${pid} is bound to $(color "${file_descriptor_count}" "${YELLOW_BOLD}") file descriptors:"
        cat "${temp_file}"
        confirm "Operation" "Proceed?" --abort
    fi

    do_kill_by_pid "${pid}"
    rm "${temp_file}"
}

do_kill_by_pid() {
    local pid="${1}"
    local stripped trimmed
    stripped=$(echo "${pid}" | sed 's/\x1b\[[0-9;]*m//g')
    trimmed="$(trim "${stripped}")"

    if ! kill "${trimmed}"; then
        if ! kill -9 "${trimmed}"; then
            err "Could not kill process ${pid} by any means."
        else
            echo "Killed process ${pid} wth a SIGTERM"
        fi
    else
        echo "Killed process ${pid}"
    fi
}

kill_process_by_name() {
    local name="${1}"
    local pid_count

    echo "Attempting to kill processes named ${name}"

    trap 'rm -f "$temp_file"' EXIT
    temp_file=$(mktemp)

    port | awk -v name="${name}" '$1 ~ name {print $0}' > "${temp_file}"
    mapfile -t pids < <(awk '{print $2}' "${temp_file}" | sort -u)
    pid_count="${#pids[@]}"

    if [[ $pid_count -eq 0 ]]; then
        echo "Could not find any process named ${name}"
        return 0
    elif [[ $pid_count -gt 1 ]]; then
        echo -e "$(color "${pid_count}" "${YELLOW_BOLD}") file descriptors match this name:"
        echo ""
        cat "${temp_file}"
        confirm "Operation" "Proceed?" --abort
    fi

    for pid in "${pids[@]}"; do
        kill_process_by_pid "${pid}"
    done
}

kill_process_by_port() {
    local port="${1}"
    local pid_count

    echo "Attempting to kill processes at port ${port}"

    mapfile -t pids < <(lsof -ti :"${port}")
    mapfile -t names < <(lsof -ti :"${port}" | xargs -r ps -p | awk 'NR>1 {print $NF}' | sort -u)
    count=${#names[@]}
    echo "pid count: ${count}"

    if [[ $count -eq 0 ]]; then
        echo "No processes found listening on port ${port}"
        return 0
    elif [[ $count -gt 1 ]]; then
        echo -e "This port is bound to $(color "${count}" "${YELLOW_BOLD}") processes:"
        echo ""
        local pid_array=("${pids[@]}")
        pids_string=$(IFS=,; echo "${pid_array[*]}")
        port | awk -v pids="$pids_string" '
            BEGIN {
                split(pids, pid_array, ",")
                for (i in pid_array) {
                    pid_set[pid_array[i]] = 1
                    print "Added PID to set: " pid_array[i]
                }
            }
            {
                for (pid in pid_set) {
                    if ($0 ~ pid) {
                        print "Match found: " $0
                        next
                    }
                }
            }
        '
        confirm "Operation" "Proceed?" --abort
    fi

    for pid in "${pids[@]}"; do
        kill_process_by_pid "${pid}"
    done
}

kill_process() {
    if [[ $# -eq 0 || ("${1}" == "-"* && -z "${2}") ]]; then
        get_help "port-kill"
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
                kill_process_by_name "${2}"
                return 0
                ;;
            *)
                get_help "port-kill"
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
        k|kill)
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
