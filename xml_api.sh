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
    manifest=$(cat $manifest_file)

    # add new remote node to manifest file
    xmlstarlet ed -L -a /manifest/remote[1] -t elem -n remoteTMP -v "" \
	             -i //remoteTMP -t attr -n "name" -v $REMOTE_NAME \
	             -i //remoteTMP -t attr -n "fetch" -v "ssh://git@$GITLAB_SRV/$TOP_GROUP" \
                     -r //remoteTMP -v remote \
                     $manifest_file
    # update original aosp node to official aosp
    xmlstarlet ed -L -u "//remote[@name='aosp']/@fetch" -v \"$AOSP_FETCH\" \
                     -u "//remote[@name='aosp']/@review" -v \"$AOSP_REVIEW\" \
                     $manifest_file

    # List all project names
    names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n < <(echo $manifest)))

    #for name in "${names[@]}"; do
    #    projects[${name}]=""
    #done

    #for item in "${!projects[@]}"; do
    for item in "${names[@]}"; do
        # Get their paths with their names as keys
        # xmlstarlet sel -t -m '/manifest/project[@name="docs/common"]' -v './@path' -n /tmp/manifest.xml
        projects[${item}]=$(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@path" < <(echo $manifest))
    done

    case "$2" in
        'all')
            for item in "${names[@]}"; do
                xmlstarlet ed -L -u "//project[@name=\"${item}\"]/@remote" -v "$REMOTE_NAME" \
                                 -u "//project[@name=\"${item}\"]/@revision" -v "$NEW_BRANCH" \
                                 $manifest_file
            done
            ;;
        'nonaosp')
            for item in "${names[@]}"; do
		# prjs is an array with 2 elements: (remote revision)
		prjs=($(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@remote" -n -v "./@revision" < <(echo $manifest)))
		# If a specific remote or revision defined for the project, we assume the code is different from the default aosp. Pick it 
		# out for pushing onto gitlab later.
		if [[ "${#prjs[@]}" -eq 0 ]]; then 
                    unset 'projects[$item]'
                else
		    xmlstarlet ed -L -u "//project[@name=\"${item}\"]/@remote" -v "$REMOTE_NAME" \
			             -u "//project[@name=\"${item}\"]/@revision" -v "$NEW_BRANCH" \
				     $manifest_file
                fi
                unset 'prjs'
            done
            ;;
        *)
            ;;
    esac

    #echo ${#projects[@]}
}
