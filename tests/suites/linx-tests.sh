#!/usr/bin/env bash

# This file is licensed under the MIT License.
# See the LICENSE file in the project root for more information:
# https://github.com/Julien-Fischer/linx/blob/master/LICENSE

export LINX_TESTS=(
    "linx_not_throws"
)

linx_not_throws() {
    linx -v
}

decluster_declusters_input_arguments() {
    local actual_a=$(decluster -abcd)
    local expected_a=(-a -b -c -d)
    local actual_b=$(decluster param1 param2 -abcd)
    local expected_b=(param1 param2 -a -b -c -d)
    local actual_c=$(decluster -abcd param1 param2 -xyz --long-option)
    local expected_c=(-a -b -c -d param1 param2 -x -y -z --long-option)
    local actual_d=$(decluster param)
    local expected_d=(param)

    assert_equals actual_a expected_a
    assert_equals actual_b expected_b
    assert_equals actual_c expected_c
    assert_equals actual_d expected_d
}