# Get the content of the manifest xml
# can do it this way:
# names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n < <(.repo/repo/repo manifest)))
#
# but we'd better save it first for further processing

# Extract all projects from manifest
# INPUT: an associative array by name reference
#        parsing type
#        the path where the updated manifest will be stored
# OUTPUT: Name and Path pairs in the associative array
function parse_manifest()
{
    local -n projects="$1"
    local manifest_file="$3"

    manifest_file=${manifest_file%/}
    manifest_file="$manifest_file/default.xml"
    .repo/repo/repo manifest > $manifest_file

    # add new remote node to manifest file
    xmlstarlet ed -L -a /manifest/remote[1] -t elem -n remoteTMP -v "" \
	             -i //remoteTMP -t attr -n "name" -v $REMOTE_NAME \
	             -i //remoteTMP -t attr -n "fetch" -v "ssh://git@$GITLAB_SRV/$TOP_GROUP" \
                     -r //remoteTMP -v remote \
                     $manifest_file
    # update original aosp node to official aosp
    xmlstarlet ed -L -u "//remote[@name='aosp']/@fetch" -v $AOSP_FETCH \
                     -u "//remote[@name='aosp']/@review" -v $AOSP_REVIEW \
                     $manifest_file

    #manifest=$(cat $manifest_file)

    # List all project names
    #names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n < <(echo $manifest)))
    #names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n $manifest_file))

    #for name in "${names[@]}"; do
    #    projects[${name}]=""
    #done

    #for item in "${!projects[@]}"; do
    #for item in "${names[@]}"; do
        # Get their paths with their names as keys
        # xmlstarlet sel -t -m '/manifest/project[@name="docs/common"]' -v './@path' -n /tmp/manifest.xml
        #projects[${item}]=$(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@path" < <(echo $manifest))
        #projects[${item}]=$(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@path" $manifest_file)
    #done

    case "$2" in
        'all')
            for item in "${names[@]}"; do
                xmlstarlet ed -L -u "//project[@name=\"${item}\"]/@remote" -v "$REMOTE_NAME" \
		                 -i "//project[@name=\"${item}\"][not(@remote)]" -t attr -n remote -v "$REMOTE_NAME" \
                                 -u "//project[@name=\"${item}\"]/@revision" -v "$NEW_BRANCH" \
		                 -i "//project[@name=\"${item}\"][not(@revision)]" -t attr -n revision -v "$NEW_BRANCH" \
                                 $manifest_file
            done

	    # make projects an (name path) associative array
            names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n $manifest_file))
            for item in "${names[@]}"; do
                projects[${item}]=$(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@path" $manifest_file)
            done
            ;;
        'nonaosp')
            printf "analyzing manifest...\n"

            names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n $manifest_file))
	    # rk/platform/vendor/rockchip/hardware, "hardware" will be 
	    # regarded as a group(directory). However, it is actually a project. 
	    # rk/platform/vendor/rockchip/hardware/codec2
	    # rk/platform/vendor/rockchip/hardware/neuralnetworks
	    # rk/platform/vendor/rockchip/hardware/rksoundsetting
	    # rk/platform/vendor/rockchip/hardware/rockit
	    # previous 4 projects will be affected.
	    # So we need to fix their paths.
            for item1 in "${names[@]}"; do
	        # make projects an (name path) associative array
                projects[${item1}]=$(xmlstarlet sel -t -m "/manifest/project[@name=\"${item1}\"]" -v "./@path" $manifest_file)

		# prjs is an array with 2 elements: (remote revision)
		#prjs=($(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@remote" -n -v "./@revision" < <(echo $manifest)))
		prjs=($(xmlstarlet sel -t -m "/manifest/project[@name=\"${item1}\"]" -v "./@remote" -n -v "./@revision" $manifest_file))

		# If a specific remote or revision defined for the project, we assume the code is different from the default aosp. Pick it 
		# out for pushing onto gitlab later.
		if [[ "${#prjs[@]}" -eq 0 ]]; then 
                    unset 'projects[$item1]'
                else
		    xmlstarlet ed -L -u "//project[@name=\"${item1}\"]/@remote" -v "$REMOTE_NAME" \
		                     -i "//project[@name=\"${item1}\"][not(@remote)]" -t attr -n remote -v "$REMOTE_NAME" \
			             -u "//project[@name=\"${item1}\"]/@revision" -v "$NEW_BRANCH" \
		                     -i "//project[@name=\"${item1}\"][not(@revision)]" -t attr -n revision -v "$NEW_BRANCH" \
				     $manifest_file
                fi
                unset 'prjs'
                for item2 in "${names[@]}"; do
                    if [[ $item1 == *"$item2/"* ]]; then
                        if [[ $item1 == $item2 ]]; then
                            continue
                        else
                            if [[ ! -z ${projects[$item1]} ]]; then
                                tmp_str=${item1#$item2}
                                new_name=${item2%/}
                                new_name=${new_name%/*}
                                new_name=${new_name%/}
                                new_name=${new_name}${tmp_str}

                                unset 'projects[$item1]'
                                projects[${new_name}]=$(xmlstarlet sel -t -m "/manifest/project[@name=\"${item1}\"]" -v "./@path" $manifest_file)

                                xmlstarlet ed -L -u "//project[@name=\"${item1}\"]/@name" -v "$new_name" $manifest_file
                            fi
                        fi
                    fi
                done
            done
            unset names
            ;;
        *)
            ;;
    esac

    #echo ${#projects[@]}
}
