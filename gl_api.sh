TOKEN="WGj-1hBBVYwZSj7S6Ts-"
URL="https://gitsrv-android.ieiworld.com"
GITLAB_API="${URL}/api/v4"

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

function gl_list_dir()
{
    local dir=$1
    local dir_id=$(gl_dir_id "$dir")

    if [ ! -z "$dir_id" ]; then
	local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" -XGET "${GITLAB_API}/groups/${dir_id}/subgroups")
	local sub_dirs=$(echo $query | jq '.[].path as $paths|@sh "[\($paths)]=\(map(select(.path == $paths).id) | join(" "))"')
	echo $sub_dirs
    fi
}

function gl_list_dir_id()
{
    local dir=$1
    local dir_id=$(gl_dir_id "$dir")

    if [ ! -z "$dir_id" ]; then
	local query=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" -XGET "${GITLAB_API}/groups/${dir_id}/subgroups")
	declare -A sub_dirs=($(echo $query | jq -r '.[].path as $paths|@sh "[\($paths)]=\(map(select(.path == $paths).id))"'))
	echo $sub_dirs
    fi
}

function gl_create_path()
{
    echo $0
}
