#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

# A smoke test asserting that the Test environment is set up
linx_core_is_installed() {
    if [[ ! -f "${HOME}/linx.sh" ]]; then
        echo "E: linx.sh is not installed"
        exit 1
    fi
}

linx_core_is_installed

echo "Smoke test passed"

