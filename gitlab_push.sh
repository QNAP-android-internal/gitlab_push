#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

TOP_GROUP="sw2_android_rk356x_group"
NEW_BRANCH="iei-android-12.1.0_r8"

source ${SCRIPTPATH}/gl_api.sh
source ${SCRIPTPATH}/xml_api.sh

function Test_gl_list_dir_id()
{
    declare -A dirids
    gl_list_dir_id dirids "${TOP_GROUP}"
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
    subdirs=$(gl_list_dir_recursive ${TOP_GROUP})
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

function Test_gl_create_project()
{
    local path="$1"
    gl_create_project "$path"
}

function Test_gl_push_project()
{
    local path="$1"
    gl_create_project "$path"
    gl_push_project "$path"
}
#echo "Test functions..."
DTest_gl_push_project "${TOP_GROUP}/tools/acloud"
#Test_gl_create_project "${TOP_GROUP}/testProject1"
#Test_gl_create_project "${TOP_GROUP}/testDir1/testProject2"
#Test_gl_create_project "${TOP_GROUP}/testDir2/testDir3/testProject3"
#Test_gl_create_project "${TOP_GROUP}/testProject2"
#Test_gl_create_project "${TOP_GROUP}/testProject3"
#Test_gl_create_path "${TOP_GROUP}/platform/build/bazel"
#Test_gl_create_path "${TOP_GROUP}/platform/build/maketool"
#Test_gl_create_path "${TOP_GROUP}/platform/build/tools"
#Test_gl_create_path "${TOP_GROUP}/development/tools"
#Test_gl_create_path "${TOP_GROUP}/development/devel_tools"
#Test_gl_create_path "${TOP_GROUP}/device/rk356x"

#id=$(gl_path_id "${TOP_GROUP}/platform/build")
#echo "Path id is $id"
#gl_del_path "${TOP_GROUP}/platform"
#gl_del_path "${TOP_GROUP}/development"
#gl_del_path "${TOP_GROUP}/device"
