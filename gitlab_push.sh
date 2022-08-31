#!/bin/bash
TOP=`pwd`
TOP_DIR="sw2_android_rk356x_group"

source ${TOP}/gl_api.sh

listdir=$(gl_list_dir "${TOP_DIR}")
echo $listdir
#declare -A dirids=$(gl_list_dir_id "${TOP_DIR}")
#echo "${#dirids[@]}"
#if [ -z "$dirids" ]; then
#    echo "There is no sub dirs under!"
#else
#    for subdir in ${!dirids[@]}; do
#        echo "$subdir ${dirids[$subdir]}"
#    done
#fi
