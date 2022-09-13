# Get the content of the manifest xml
# can do it this way:
# names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n < <(.repo/repo/repo manifest)))
#
# but we'd better save it first for further processing

# Extract all projects from manifest
# INPUT: an associative array by name reference
# OUTPUT: Name and Path pairs in the associative array
function parse_manifest()
{
    local -n projects="$1"

    manifest=$(cat < <(.repo/repo/repo manifest))

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
            ;;
        'nonaosp')
            for item in "${names[@]}"; do
		# prjs is an array with 2 elements: (remote revision)
		prjs=($(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@remote" -n -v "./@revision" < <(echo $manifest)))
		# If a specific remote or revision defined for the project, we assume the code is different from the default aosp. Pick it 
		# out for pushing onto gitlab later.
		if [[ "${#prjs[@]}" -eq 0 ]]; then 
                    unset 'projects[$item]'
                fi
                unset 'prjs'
            done
            ;;
        *)
            ;;
    esac

    #echo ${#projects[@]}
}
