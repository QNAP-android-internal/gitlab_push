# Get the content of the manifest xml
# can do it this way:
# names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n < <(.repo/repo/repo manifest)))
#
# but we'd better save it first for further processing
function parse_manifest()
{
    manifest=$(cat < <(.repo/repo/repo manifest))

    # List all project names
    names=($(xmlstarlet sel -t -v "/manifest/project/@name" -n < <(echo $manifest)))

    declare -A repo_projects
    for name in "${names[@]}"; do
        repo_projects[${name}]=""
    done

    for item in "${!repo_projects[@]}"; do
        # Get their paths with their names as keys
        # xmlstarlet sel -t -m '/manifest/project[@name="docs/common"]' -v './@path' -n /tmp/manifest.xml
        repo_projects[${item}]=$(xmlstarlet sel -t -m "/manifest/project[@name=\"${item}\"]" -v "./@path" < <(echo $manifest))
        echo "[$item] = ${repo_projects[$item]}"
    done
}
