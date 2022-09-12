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
                prj_remote=$(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@remote" < <(echo $manifest))
		# Assume that if no remote defined for the specific project, the default remote is aosp.
                if [[ -z "${prj_remote}" ]]; then
                    unset 'projects[$item]'
                fi
                unset 'prj_remote'
            done
            ;;
        *)
            ;;
    esac

    #echo ${#projects[@]}
}
