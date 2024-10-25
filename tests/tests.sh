#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

###############################################################
## Tests to run
###############################################################

declare -a TESTS_TO_RUN=(
    "linx_core_is_installed"
)


###############################################################
## Tests constants
###############################################################
readonly APP_DIR=/app/test_env
readonly CURRENT_DATE=$(date +%Y-%m-%d)
# output colors
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly BLUE='\033[1;34m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

###############################################################
## Lifecycle
###############################################################

exec_test() {
    # Before all
    func_name="$1"
    # Execute test
    $func_name
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    # After all
}

before_each() {
    cd "${APP_DIR}" || exit 1
}

#after_each() {
#    reinstall
#}

execute_tests() {
    local n=${#TESTS_TO_RUN[@]}
    local suite_color=$GREEN
    local pass_count=0
    local fail_count=0
    print_separator
    for ((i=0; i < ${n}; i++)); do
        local func="${TESTS_TO_RUN[i]}"
        status='Failed'
        color=$RED
        before_each
        echo -e "${i} - ${YELLOW}Running${NC} ${BLUE}${func}${NC}"
        test $func
        local passed=$?
        if [ $passed -eq 0 ]; then
            status='Passed'
            color=$GREEN
            pass_count=$((pass_count + 1))
        else
            suite_color=$RED
            fail_count=$((fail_count + 1))
        fi
        echo -e "${color}Status: ${status}${NC}"
        if [[ $i -lt $((n - 1)) ]]; then
            echo ""
        fi
#        after_each
    done
    print_separator
    echo -e "${GREEN}${pass_count}${NC} passed. ${RED}${fail_count}${NC} failed."
    echo -e "[$(date '+%H:%M:%S')] ${suite_color}Tests passed${NC}."
}

print_separator() {
    echo -e "${YELLOW}_______________________________________________________________${NC}"
}

###############################################################
## Tests
###############################################################

# A smoke test asserting that the Test environment is set up
linx_core_is_installed() {
    if [[ ! -f "${HOME}/linx.sh" ]]; then
        echo "E: linx.sh is not installed"
        exit 1
    fi
}



###############################################################
## Execute tests
###############################################################

echo "[$(date '+%H:%M:%S')] Executing tests..."
linx -v
execute_tests
