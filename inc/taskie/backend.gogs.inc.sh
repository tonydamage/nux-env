nux.use taskie/backend.utils
nux.use nux.json
backend.gogs.list() {
  local api="$gogs_api_url/repos/$gogs_repository/issues?token=$gogs_api_token"
  local append_next="&token=$gogs_api_token"

  backend.githublike.get "$api" "$append_next" \
    | jq -r ".[] | [.number,.state,(\"#\" + .labels[].name) ,.title] | @sh" \
    | while read line
      do
        eval taskie.issue.display.short $line
      done
}

argz() {
  int=0;
  for arg in "$@"
  do
    let int=int+1
    echo $int $arg
  done
}

backend.gogs.issue.exists() {
  local message="$@"
  nux.json.start
  nux.json.open "$gogs_issuemap"
  id=$(nux.json.read "\"$gogs_api_url\".\"$gogs_repository\".\"$message\"")
  nux.log debug "Message Id is $id"
  test "$id" != null #-o -n "$id";
}

backend.gogs.detect() {
  closest_git=$(nuxfs.closest .git "$1")
  git.origins "$closest_git" | while read origin
  do
    nux.log debug Testing backend for: $origin
    optlist=$(nux.url.parse "$origin" "\1\3\5\6\8 \5\6\8 \5\8 \5\6 \5")
    repository=$(nux.url.parse "$origin" "\9" | sed -s "s/\.git\$//")
    for opt in $optlist; do
      gogs_api_url=$(gogs.config.site "$opt" ".api.url")
      if [ -n "$gogs_api_url" ]; then
        echo $repository:$closest_git:$opt
        return 0;
      fi
    done
  done
}

backend.gogs.with() {
  gogs_repository=$(echo $backendId | cut -d: -f2)
  gogs_configId=$(echo $backendId | cut -d: -f4)

  gogs_api_url=$(gogs.config.site "$gogs_configId" .api.url)
  gogs_api_token=$(gogs.config.site "$gogs_configId" .api.token)
  gogs_issuemap=$(nux.cfg.dir.global)/gogs.issuemap.json
  nux.log debug Gogs repository is $gogs_repository;
  nux.log debug Gogs API URL: $gogs_api_url;

}

backend.gogs.add() {

  echo "Adding issue:" "\"$@\""

  local message="$@"
  local payload="{\"title\": \"$message\",\"body\": \"$message\"}"
  local api="$gogs_api_url/repos/$gogs_repository/issues?token=$gogs_api_token"
  nux.log debug Repository is $gogs_repository, message is $message
  nux.log debug API call: $api Payload: $payload
  remId=$(curl -s -H "Content-Type: application/json" -X POST -d "$payload" "$api" | jq -r .number)

  nux.json.start
  nux.json.open "$gogs_issuemap"
  nux.json.write "\"$gogs_api_url\".\"$gogs_repository\".\"$message\"" $remId
  nux.json.flush "$gogs_issuemap"

  echo Issue Number is: $remId

}
