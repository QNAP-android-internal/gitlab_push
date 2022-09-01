#!/bin/bash
TOP=`pwd`
TOP_DIR="sw2_android_rk356x_group"

source ${TOP}/gl_api.sh

function Test_gl_list_dir_id()
{
    declare -A dirids
    gl_list_dir_id dirids "${TOP_DIR}"
    if [ "${#dirids[@]}" -eq "0" ]; then
        echo "There is no sub dirs under!"
    else
        for subdir in ${!dirids[@]}; do
            echo "The id of $subdir is ${dirids[$subdir]}"
        done
    fi
}

### This feature needs gitlab version 13.5 or above
function Test_gl_list_dir_recursive()
{
    subdirs=$(gl_list_dir_recursive ${TOP_DIR})
    if [ "${#subdirs[@]}" -eq "0" ]; then
        echo "There is no sub dirs under!"
    else
        for path in ${subdirs}; do
            echo "${path}"
        done
    fi
}

function Test_gl_create_path()
{
    local path="$1"
    gl_create_path "$path"
}

echo "Test functions..."
#Test_gl_create_path "${TOP_DIR}/platform/build/tools"
#Tbest_gl_create_path "${TOP_DIR}/platform/build/maketool"
#Test_gl_create_path "${TOP_DIR}/development/tools"
#Test_gl_create_path "${TOP_DIR}/device/rk356x"

id=$(gl_path_id "${TOP_DIR}/platform/build")
echo "Path id is $id"
gl_del_path "${TOP_DIR}/platform"
gl_del_path "${TOP_DIR}/development"
gl_del_path "${TOP_DIR}/device"
