TOKEN="WGj-1hBBVYwZSj7S6Ts-"
URL="https://gitsrv-android.ieiworld.com"
GITLAB_API="${URL}/api/v4"

# INPUT: $1 as directory
# OUTPUT: get the directory(group) id of $1 dir
function gl_dir_id()
{
    local dir=$1
    local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" --request GET --url "${GITLAB_API}/groups")
    local num=$(echo $query | jq --argjson i "[\"$dir\"]" 'map(select(.path==$i[])) | length')

    if [ "$num" -ne "0" ]; then
	local id=$(echo $query | jq --argjson i "[\"$dir\"]" '.[]|select(.path==$i[])|.id')
	echo $id
    fi
}

# INPUT: $1 as path
# OUTPUT: get the dir id of $1 path
function gl_path_id()
{
    local path=$1
    local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" --request GET --url "${GITLAB_API}/groups")
    local id=$(echo $query | jq --argjson i "[\"$path\"]" '.[]|select(.full_path==$i[])|.id')
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
# OUTPUT: an associative array of path name and its id
function gl_create_path()
{
    local path=$1
    local components
    IFS="/" components=( $path )

    for dir in "${components[@]}"; do
        local dir_id=$(gl_path_id "$dir")
	local parent_dir_id
	if [ ! -z "$dir_id" ]; then
            parent_dir_id="$dir_id"
        else
	    local json_data="{\"name\": \"${dir}\", \"path\": \"${dir}\", \"visibility\": \"internal\", \"description\": \"${dir}\"}"
            parent_dir_id=$(curl -s --request POST --header "PRIVATE-TOKEN: $TOKEN" --header "Content-Type: application/json" \
		            --data "$json_data" \
		            "${GITLAB_API}/groups?parent_id=$parent_dir_id" | jq '.id')
            unset dir_id
        fi
    done
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
# OUTPUT: an associative array of dir/project name and their ids
function gl_create_project()
{
    local path="$1"
    local dir=$(dirname "$path")
    local project=$(basename "$path")

    if [ ! -z "$dir" ]; then
        gl_create_path $dir
    fi	

    if [ ! -z "$project" ]; then
       PROJECT1_ID=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" -XPOST "${GITLAB_API}/projects?name=MyCFProject&visibility=private&namespace_id=$SUB_GROUP1_ID" | jq '.id') 
    fi	
}
