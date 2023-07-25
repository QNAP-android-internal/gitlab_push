# INPUT: $1 as directory
# OUTPUT: get the directory(group) id of $1 dir
function gl_dir_id()
{
    local dir=$1
    local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" --request GET --url "${GITLAB_API}/groups")
    local num=$(echo $query | jq --argjson i "[\"$dir\"]" 'map(select(.path==$i[])) | length')

    if [[ "$num" -ne "0" ]]; then
	local id=$(echo "$query" | jq --argjson i "[\"$dir\"]" '.[]|select(.path==$i[])|.id')
	echo $id
    fi
}

# INPUT: $1 as path
# OUTPUT: get the dir id of $1 path
function gl_path_id()
{
    local tmp="$1"
    local query
    local id
    # strip leading slash
    tmp=${tmp#/}
    # strip trailing slash
    tmp=${tmp%/}
    pages=$(curl -s --head "${GITLAB_API}/groups?private_token=$TOKEN&per_page=100" | grep x-total-pages | awk '{print $2}' | tr -d '\r\n')
    for page in $(seq 1 $pages); do
        query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" --request GET "${GITLAB_API}/groups?per_page=100&page=$page")
        id=$(echo "$query" | jq --argjson i "[\"$tmp\"]" '.[]|select(.full_path==$i[])|.id')
        if [[ -n "$id" ]]; then
            break
        fi
    done

    echo $id
}

# INPUT: $1 directory
# OUTPUT: list sub directories under $1 dir
function gl_list_dir()
{
    local dir=$1
    local dir_id=$(gl_dir_id "$dir")

    if [ ! -z "$dir_id" ]; then
	local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" -XGET "${GITLAB_API}/groups/${dir_id}/subgroups")
	local sub_dirs=$(echo $query | jq '.[].path')
	echo $sub_dirs
    fi
}

# INPUT: $1 directory
# OUTPUT: list sub directories recursively under $1 dir
# This API need Gitlab version 13.5 or above
function gl_list_dir_recursive()
{
    local dir=$1
    local dir_id=$(gl_dir_id "$dir")

    if [ ! -z "$dir_id" ]; then
	local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" -XGET "${GITLAB_API}/groups/${dir_id}/descendant_groups")
	local sub_dirs=$(echo $query | jq '.[].path')
	echo $sub_dirs
    fi
}

# INPUT: $1 an associative array with path as the key and id the value
#        $2 directory
# OUTPUT: list sub directories and their ids under $2 dir
function gl_list_dir_id()
{
    local -n dirids_array="$1"
    local dir=$2
    local dir_id=$(gl_dir_id "$dir")

    if [ ! -z "$dir_id" ]; then
	local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" -XGET "${GITLAB_API}/groups/${dir_id}/subgroups")
        #dirids_array="($(echo $query | jq -r '.[].path as $paths|@sh "[\($paths)]=\(map(select(.path == $paths).id)|join(" "))"'))"
	#echo "${#dirids_arry[@]}"
        while IFS="=" read -r key value
        do
            dirids_array["$key"]=$value
	done < <(echo $query | jq -r '.[].path as $paths|@sh "\($paths)=\(map(select(.path == $paths).id))"')
    fi
}

# INPUT: $1 as path. eg. foo/bar will be created respectively
# OUTPUT: the created folder(subgroup) id
function gl_create_path()
{
    local path="$1"
    local -a components
    local temp_dir
    local parent_dir_id
    local dir_id
    IFS="/" components=($path)

    for dir in "${components[@]}"; do
	temp_dir="${temp_dir}/${dir}"
        dir_id=$(gl_path_id "$temp_dir")
        #dir_id=$(gl_dir_id "$dir")
	if [[ -n "$dir_id" ]]; then
            parent_dir_id="$dir_id"
        else
	    local json_data="{\"name\": \"${dir}\", \"path\": \"${dir}\", \"parent_id\": \"${parent_dir_id}\", \"visibility\": \"internal\",\"description\": \"${dir}\"}" 
	    parent_dir_id=$(curl -s --request POST --header "PRIVATE-TOKEN: $TOKEN" --header "Content-Type: application/json" --data "$json_data" "${GITLAB_API}/groups" | jq '.id')
            unset dir_id
        fi
    done

    echo $parent_dir_id
}

# INPUT: $1 as path. Delete the dir recursively. eg. foo/bar deleting everything under directory bar including bar itself.
# OUTPUT: null
function gl_del_path()
{
    local path=$1
    local id=$(gl_path_id "$path")

    if [ ! -z "$id" ]; then
	local result=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" --request DELETE --url "${GITLAB_API}/groups/${id}")
    fi    
}

# INPUT: $1 as path. eg. foo/bar. the last component of path is
#        regarded as the project name.
# OUTPUT: the created project id
function gl_create_project()
{
    local path="$1"
    local project=$(basename "$path")
    local project_id
    local path_id
    path=$(dirname "$path")

    if [[ -n "$path" ]]; then
	path_id=$(gl_create_path "$path")
    fi	

    if [[ -n "$project" ]]; then
        local json_data="{\"name\": \"${project}\", \"path\": \"${project}\",  \"namespace_id\": \"${path_id}\",  \"visibility\": \"internal\", \"description\": \"${project}\",  \"initialize_with_readme\": \"false\"}"
        project_id=$(curl -s --request POST --header "PRIVATE-TOKEN: $TOKEN" --header "Content-Type: application/json" --data "$json_data" --url "${GITLAB_API}/projects" | jq '.id')
    fi	

    echo $project_id
}

# INPUT: $1 as project name and $2 as project path
# OUTPUT: null
function gl_push_project()
{
    local name="$1"
    local path="$2"
    cd "$path"

    #git remote rename origin old-origin
    #git remote remove origin

    # Add the remote if the remote doesn't exist
    git config remote.${REMOTE_NAME}.url >&- || git remote add ${REMOTE_NAME} git@${GITLAB_SRV}:${TOP_GROUP}/${name}.git
    # Create the branch if the branch doesn't exist
    git show-ref --verify --quiet refs/heads/${NEW_BRANCH} || git checkout -b ${NEW_BRANCH}
    #git push -u ${REMOTE_NAME} --all
    git push -u ${REMOTE_NAME} ${NEW_BRANCH}:${NEW_BRANCH}
    #git push -u ${REMOTE_NAME} --tags

    cd - > /dev/null
}
