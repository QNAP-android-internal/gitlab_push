#!/bin/bash
TOP=`pwd`
TOP_DIR="sw3_android_rk356x_group"

source ${TOP}/gl_api.sh

declare -A dirids
gl_list_dir_id dirids "${TOP_DIR}"
if [ "${#dirids[@]}" -eq "0" ]; then
    echo "There is no sub dirs under!"
else
    for subdir in ${!dirids[@]}; do
        echo "The id of $subdir is ${dirids[$subdir]}"
    done
fi
