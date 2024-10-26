#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

export BACKUP_TESTS=(
    "backup_not_throws"
)

backup_not_throws() {
    local expected="expected"
    echo $expected > a

    backup a

    if [[ ! -f a.bak ]] || ! grep -q ${expected} a.bak; then
        return 1
    fi
}