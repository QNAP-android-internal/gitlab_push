TOKEN="WGj-1hBBVYwZSj7S6Ts-"
URL="https://gitsrv-android.ieiworld.com"
GITLAB_API="${URL}/api/v4"

function gl_dir_id()
{
    local dir=$1
    local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" --request GET --url "${GITLAB_API}/groups")
    local num=$(echo $query | jq --argjson i "[\"$dir\"]" 'map(select(.path==$i[])) | length')

    if [ "$num" -eq "0" ]; then
        return 0
    else
	local id=$(echo $query | jq --argjson i "[\"$dir\"]" '.[]|select(.path==$i[])|.id')
        return $id
    fi
}

function gl_list_dir()
{
    local dir=$1
    gl_dir_id "$dir"
    local id=$?
    if [ "$id" -eq "0" ]; then
        echo "$dir does not exist!"
	return 0
    else
	local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" -XGET "${GITLAB_API}/groups/${id}/subgroups")
	local sub_dirs=$(echo $query | jq '.[].path as $paths|@sh "[\($paths)]=\(map(select(.path == $paths).id) | join(" "))"')
	echo $sub_dirs
	return 1
    fi
}

function gl_list_dir_id()
{
    local dir=$1
    gl_dir_id "$dir"
    local id=$?
    if [ "$id" -eq "0" ]; then
        echo "$dir does not exist!"
	return 0
    else
	local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" -XGET "${GITLAB_API}/groups/${id}/subgroups")
	local sub_dirs=$(echo $query | jq '.[].path as $paths|@sh "[\($paths)]=\(map(select(.path == $paths).id) | join(" "))"')
	echo $sub_dirs
	return 1
    fi
}

function gl_create_path()
{
    echo $0
}
