#!/bin/bash
TOP=`pwd`
TOP_DIR="sw2_android_rk356x_group"

source ${TOP}/gl_api.sh

declare -A dirs=$(gl_list_dir_id "${TOP_DIR}")
if [ -z "$dirs" ]; then
    echo "There is no sub dirs under!"
else
    for subdir in ${dirs[@]}; do
        echo $subdir
    done
fi
