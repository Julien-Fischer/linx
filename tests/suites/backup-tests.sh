#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

export BACKUP_TESTS=(
    "backup_without_parameters_throws"
    "backup_without_options_copies_file_with_bak_extension"
)

backup_without_parameters_throws() {
    backup &>/dev/null
    if $? -ne 0 ; then
        return 1
    fi
}

backup_without_options_copies_file_with_bak_extension() {
    local expected="expected"
    echo $expected > a

    backup a

    if [[ ! -f a.bak ]] || ! grep -q ${expected} a.bak; then
        return 1
    fi
}