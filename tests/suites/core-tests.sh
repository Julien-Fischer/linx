#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

export CORE_TESTS=(
    "linx_core_is_installed"
    "lt_lists_dir_content"
)

# A smoke test asserting that the Test environment is set up
linx_core_is_installed() {
    if [[ ! -f "${HOME}/linx.sh" ]]; then
        echo "E: linx.sh is not installed"
        return 1
    fi
}

lt_lists_dir_content() {
    if ! lt > /dev/null; then
        return 1
    fi
}