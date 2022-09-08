#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
# A global associative arrsy storing project name and path pairs for further processing

source ${SCRIPTPATH}/configs
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
#Test_gl_push_project "${TOP_GROUP}/tools/acloud"
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

printf "Parsing manifest...\n"

declare -A repo_projects
# 'all' for all projects and 'nonaosp' for non aosp projects
#total_projects=$(parse_manifest repo_projects "nonaosp")
parse_manifest repo_projects "nonaosp"
total_projects=${#repo_projects[@]}
count=0
for item in "${!repo_projects[@]}"; do
    printf "########## Processing %s ##########\n" $item
    name=$item
    if [ "x${repo_projects[$item]}" = "x" ]; then
        path=$name
    else
        path=${repo_projects[$item]}
    fi

    printf "Creating project %s on gitlab...\n" $item
    project_id=$(gl_create_project "${TOP_GROUP}/${name}")
    printf "%s id is %d\n" $item $project_id

    printf "Pushing %s ...\n" $item
    gl_push_project "${name}" "${path}"
    ((count++))
    printf "########## %d/%d ##########\n\n" $count $total_projects
done
