#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

source ${SCRIPTPATH}/configs
source ${SCRIPTPATH}/gl_api.sh
source ${SCRIPTPATH}/xml_api.sh

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
    if [[ -z "${repo_projects[$item]}" ]]; then
        path=$name
    else
        path=${repo_projects[$item]}
    fi

    printf "Creating project %s on gitlab...\n" $item
    project_id=$(gl_create_project "${TOP_GROUP}/${name}")
    #printf "%s id is %d\n" $item $project_id

    printf "Pushing %s ...\n" $item
    gl_push_project "${name}" "${path}"
    ((count++))
    printf "########## %d/%d ##########\n\n" $count $total_projects
done
