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

SERVER_DIR="${COMMANDS_DIR}/ask.server"
SERVER_ENTRYPOINT="server.js"
SERVER_PORT="3000"
REST_ENDPOINT="http://localhost:${SERVER_PORT}/ask"
GPT_API_PROPERTY_KEY="gpt.api.key"

##############################################################
# Utils
##############################################################

init_server() {
    sudo mkdir -p "${SERVER_DIR}"
    cd "${SERVER_DIR}" || return 1
    echo "Adding API key to local server..."
    local api_key
    api_key="$(get_linx_property "${GPT_API_PROPERTY_KEY}" -q)"

    if [[ -z "${api_key}" ]]; then
        echo "${GPT_API_PROPERTY_KEY} is not defined in ${CONFIG_FILE}"
        local input
        prompt_multiline "your OpenAI API key"
        api_key="${input}"
        put_linx_property "${GPT_API_PROPERTY_KEY}" "${api_key}"
    fi

    if [[ -z "${api_key}" ]]; then
        err "ask requires a valid API key to connect to OpenAI API."
        return 1
    fi

    local tmp_file="${LINX_DIR}/.env"
    echo "OPENAI_API_KEY=\"${api_key}\"" > "${tmp_file}"
    if ! sudo mv "${tmp_file}" "${SERVER_DIR}/.env"; then
        err "Could not write OpenAI API key to ${SERVER_DIR}/.env"
        return 1
    fi
}

start_server() {
    local debug=false
    if [[ "${1}" == -x ]]; then
        debug=true
    fi
    require_sudo "start a local server to connect with ChatGPT."
    if ! init_server; then
        err "Could not initialize server configuration"
        return 1
    fi

    echo "Updating local server..."
    cd "${SERVER_DIR}" || return 1
    linx_spinner_start
    if ! sudo npm i > /dev/null; then
        err "Could not install node packages"
        return 1
    fi
    linx_spinner_stop
    echo "done."

    echo "Starting local server..."
    linx_spinner_start
    if $debug; then
        npm start "${SERVER_ENTRYPOINT}"
    else
        npm start "${SERVER_ENTRYPOINT}" &> /dev/null &
    fi
    local pid=$!
    $debug && disown
    linx_spinner_stop
    echo "done."

    echo "Server running with pid: ${pid}."
    echo "Use 'ask' to ask any question to ChatGPT."
}

stop_server() {
  PID_LIST=$(lsof -ti :"${SERVER_PORT}")

  if [[ -z "$PID_LIST" ]]; then
      echo "No processes found listening on port ${SERVER_PORT}"
      exit 0
  fi

  for PID in $PID_LIST; do
      echo "Killing process ${PID}"
      kill -9 "${PID}"
  done

  echo "All processes listening on port ${SERVER_PORT} have been terminated"
}

is_server_running() {
    if ss -tuln | grep -q ":${SERVER_PORT}\b"; then
        return 0
    else
        return 1
    fi
}

get_current_log_path() {
    local today dir current_file
    today=$(date +%Y-%m-%d)
    dir=$(get_linx_property "gpt.logs.directory")
    echo "${dir}/${today}.log"
}

rotate_log_file() {
    local current_file
    current_file="$(get_current_log_path)"
    if [[ ! -f "${current_file}" ]]; then
        touch "${current_file}"
    fi
}

http_post() {
    local url="${1}"
    local payload="${2}"
    local output_file
    output_file="$(get_current_log_path)"
    local now response answer
    now=$(timestamp)

    echo "[${now}] [question] ${payload}"
    echo "[${now}] [question] ${payload}" >> "${output_file}"

    local json
    json=$(jq -R -s . <<< "${payload}")

    response=$(curl -X POST "${url}" \
         -H "Content-Type: application/json" \
         -d "{\"question\": ${json}}" \
         -s)

    answer=$(echo "$response" | jq -r '.answer')

    echo -e "[$(timestamp)] [response] ${answer}" >> "${output_file}"
    echo "===================================" >> "${output_file}"
    echo "${answer}"
}

##############################################################
# Process
##############################################################

handle_perplexity() {
    local input="${1}"
    local query="${input// /%20}"
    firefox "https://www.perplexity.ai/search?q=${query}" &
}

handle_gpt() {
    local input="${1}"
    local debug="${2}"

    if ! is_server_running; then
        start_server "${debug}"
    fi

    rotate_log_file

    linx_spinner_start
    http_post "${REST_ENDPOINT}" "${input}"
    linx_spinner_stop
}

ask() {
    if [[ "${1}" == --help || "${1}" == "-h" ]]; then
        get_help "ask"
        return 0
    fi
    local input="${1}"
    if [[ "${input}" =~ ^- ]]; then
        input=""
    else
        shift
    fi
    local provider="gpt"
    local raw=false
    local debug=""

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -p|--provider)
                provider="${2}"
                shift
                ;;
            -r|--raw)
                raw=true
                ;;
            -x|--debug)
                debug="-x"
                ;;
            -h|--help)
                get_help "ask"
                return 0
                ;;
            *)
                err "Invalid parameter: ${1}"
                get_help "ask"
                return 1
                ;;
        esac
        shift
    done

    if [[ -z "${input}" ]]; then
        prompt_multiline
    fi

    local processed_input
    if $raw; then
        processed_input="${input}"
    else
        processed_input="$(anonymize_plain_text "${input}")"
    fi

    case $provider in
        p|perplexity)
            handle_perplexity "${processed_input}"
            ;;
        gpt)
            handle_gpt "${processed_input}" "${debug}"
            ;;
        *)
            err "Unknown provider: ${provider}. Supported values: gpt, perplexity"
            return 1
            ;;
    esac
}

ask "$@"
