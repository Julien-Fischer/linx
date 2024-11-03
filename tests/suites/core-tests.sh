#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

export CORE_TESTS=(
    'is_installed'
    'lt_lists_dir_content'
    'timestamp_uses_default_separators'
    'timestamp_uses_custom_date_separator'
    'timestamp_uses_custom_datetime_separator'
    'timestamp_uses_custom_time_separator'
    'timestamp_uses_all_custom_separators'
    'timestamp_uses_iso_datetime_format'
    'timestamp_uses_human_readable_format'
    'timestamp_uses_compact_format'
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

timestamp_uses_default_separators() {
    local result=$(timestamp)
    local expected=$(date "+%Y-%m-%d %H:%M:%S")
    assert_equals "$expected" "$result"
}

timestamp_uses_custom_date_separator() {
    local result=$(timestamp -s "/")
    local expected=$(date "+%Y/%m/%d %H:%M:%S")
    assert_equals "$expected" "$result"
}

timestamp_uses_custom_datetime_separator() {
    local result=$(timestamp -s "-" "_")
    local expected=$(date "+%Y-%m-%d_%H:%M:%S")
    assert_equals "$expected" "$result"
}

timestamp_uses_custom_time_separator() {
    local result=$(timestamp -s "-" " " ",")
    local expected=$(date "+%Y-%m-%d %H,%M,%S")
    assert_equals "$expected" "$result"
}

timestamp_uses_all_custom_separators() {
    local result=$(timestamp -s "/" "_" ",")
    local expected=$(date "+%Y/%m/%d_%H,%M,%S")
    assert_equals "$expected" "$result"
}

timestamp_uses_iso_datetime_format() {
    local result=$(timestamp -i)
    local expected=$(date "+%Y-%m-%dT%H:%M:%S")
    assert_equals "$expected" "$result"
}

timestamp_uses_human_readable_format() {
    local result=$(timestamp -h)
    local expected=$(date "+%Y-%m-%d_%H:%M:%S")
    assert_equals "$expected" "$result"
}

timestamp_uses_compact_format() {
    local result=$(timestamp -c)
    local expected=$(date "+%Y%m%d%H%M%S")
    assert_equals "$expected" "$result"
}