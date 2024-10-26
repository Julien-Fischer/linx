#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

source "${HOME}/linx.sh"
source ./tests/suites/core-tests.sh
source ./tests/suites/linx-tests.sh
source ./tests/suites/backup-tests.sh
source ./tests/suites/port-tests.sh

###############################################################
## Test suites to run
###############################################################

declare -A TESTS_TO_RUN=(
    ["core"]="${CORE_TESTS[@]}"
    ["linx"]="${LINX_TESTS[@]}"
    ["backup"]="${BACKUP_TESTS[@]}"
    ["port"]="${PORT_TESTS[@]}"
)

###############################################################
## Tests constants
###############################################################
readonly APP_DIR=/home/john/Desktop/linx
readonly CURRENT_DATE=$(date +%Y-%m-%d)
# output colors
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly BLUE='\033[1;34m'
readonly MAGENTA='\033[1;35m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

###############################################################
## Lifecycle
###############################################################

exec_test() {
    # Before all
    test_name="$1"
    # Execute test
    $test_name
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
    local suite_color=$GREEN
    local pass_count=0
    local fail_count=0
    local suite_count=0

    print_separator
    for suite_name in "${!TESTS_TO_RUN[@]}"; do
        local test_count=0
        echo -e "${MAGENTA}${suite_name}${NC} test suite"
        echo ""
        IFS=' ' read -r -a suite <<< "${TESTS_TO_RUN[$suite_name]}"
        local n=${#suite[@]}
        for current_test in "${suite[@]}"; do
            status='Failed'
            color=$RED
            before_each
            echo -e "$((test_count+1)) - ${YELLOW}Running${NC} ${BLUE}${current_test}${NC}"
            exec_test "${current_test}"
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
            if [[ $test_count -lt $((n - 1)) ]]; then
                echo ""
            fi
            test_count=$((test_count + 1))
    #        after_each
        done
        print_separator
        suite_count=$((suite_count + 1))
    done
    echo -e "${GREEN}${pass_count}${NC} passed. ${RED}${fail_count}${NC} failed."
    echo -e "[$(date '+%H:%M:%S')] ${suite_color}Tests passed${NC}."
}

print_separator() {
    echo -e "${YELLOW}_______________________________________________________________${NC}"
}

###############################################################
## Execute tests
###############################################################

echo -e "[$(date '+%H:%M:%S')] Running tests as ${GREEN}$(whoami)${NC} in ${BLUE}$(pwd)${NC} with shell ${YELLOW}$(readlink /proc/$$/exe)${NC}"
echo -e "linx version: ${GREEN}$(linx -v)${NC}"
echo -e "User permissions / groups: ${YELLOW}$(id)${NC}"
execute_tests
