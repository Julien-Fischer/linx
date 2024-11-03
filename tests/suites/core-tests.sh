#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

export CORE_TESTS=(
    'is_installed'
    'lt_lists_dir_content'
    'it_uses_default_timestamp'
    'it_uses_custom_date_separator'
    'it_uses_custom_date_time_separator'
    'it_uses_custom_time_separator'
    'it_uses_all_custom_separators'
    'it_uses_timestamp_format'
)

# A smoke test asserting that the Test environment is set up
is_installed() {
    if [[ ! -f "${HOME}/linx.sh" || ! -f "${HOME}/.linx_lib.sh" ]]; then
        echo "E: linx.sh is not installed"
        return 1
    fi
}

lt_lists_dir_content() {
    if ! lt > /dev/null; then
        return 1
    fi
}

it_uses_default_timestamp() {
    local result=$(timestamp)
    local expected=$(date "+%Y-%m-%d %H:%M:%S")
    assert_equals "$expected" "$result"
}

it_uses_custom_date_separator() {
    local result=$(timestamp "/")
    local expected=$(date "+%Y/%m/%d %H:%M:%S")
    assert_equals "$expected" "$result"
}

it_uses_custom_date_time_separator() {
    local result=$(timestamp "-" "_")
    local expected=$(date "+%Y-%m-%d_%H:%M:%S")
    assert_equals "$expected" "$result"
}

it_uses_custom_time_separator() {
    local result=$(timestamp "-" " " ",")
    local expected=$(date "+%Y-%m-%d %H,%M,%S")
    assert_equals "$expected" "$result"
}

it_uses_all_custom_separators() {
    local result=$(timestamp "/" "_" ",")
    local expected=$(date "+%Y/%m/%d_%H,%M,%S")
    assert_equals "$expected" "$result"
}

it_uses_timestamp_format() {
    local result=$(timestamp)
    assert_matches "$result" "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$"
}
