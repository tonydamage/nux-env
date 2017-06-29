githublike.common.issue.list() {
  githublike.get issues  \
    | jq -r ".[] | [.number,.state,(\"#\" + .labels[].name) ,.title] | @sh" \
    | while read line
      do
        eval taskie.issue.display.short $line
      done
}

githublike.common.issue.exists() {
  local message="$@"
  nux.json.start
  nux.json.open "$githublike_issuemap"
  id=$(nux.json.read "\"$githublike_api\".\"$githublike_repository\".\"$message\"")
  nux.log debug "Message Id is $id"
  test "$id" != null #-o -n "$id";
}

githublike.common.labels() {
  githublike.get "labels" \
   | jq -r ".[] | .name + \":\" + (.id | @text) | @text"
}

githublike.common.issue.add() {
  echo "Adding issue:" "\"$@\""
  local message="$@"

  nux.json.start

  nux.json.write title "$message"
  nux.json.write message "$message"
  if [ -n "labelId" ]; then
  nux.json.write.raw labels[0] $labelId
  fi
  local payload=$(nux.json.flush)

  nux.log debug Repository is $githublike_repository, message is $message
  nux.log debug API call: $api Payload: $payload
  remId=$(githublike.post issues "$payload" | jq -r .number)

  nux.json.start
  nux.json.open "$githublike_issuemap"
  nux.json.write "\"$githublike_api\".\"$githublike_repository\".\"$message\"" $remId
  nux.json.flush "$githublike_issuemap"

  echo Issue Number is: $remId

}

githublike.common.labels.id() {
  githublike.get "labels" \
   | jq -r ".[] | .name + \":\" + (.id | @text) | @text"
}

githublike.get() {
  local resource=$1;
  local api="${githublike_api}/repos/${githublike_repository}/${resource}${githublike_api_append}";
  nux.log debug Repository is $githublike_repository, message is $message
  nux.log debug API call: $api Payload: $payload
  header_tmp=$(mktemp);
  while [ -n "$api" ];
  do
  curl $githublike_curl_params -s -D "$header_tmp" -H "Content-Type: application/json" "$api"
  next=$(grep "Link: " "$header_tmp" | tr "," "\n" | grep rel=\"next\" | cut -d"<" -f2 | cut -d">" -f1)
  nux.log debug Next "$next";
  if [ -n "$next" ]; then
    api="${next}${githublike_next_append}"
  else
    api=""
  fi
  done;
  rm -f $header_tmp;
}

githublike.post() {
  local resource=$1
  local api="${githublike_api}/repos/${githublike_repository}/${resource}${githublike_api_append}"
  local payload="$2"
  nux.log debug POST API call: $api Payload: $payload
  curl $githublike_curl_params -s -H "Content-Type: application/json" -X POST -d "$payload" "$api"
}

githublike() {
  backend=$1;

  functions=$(set | grep -G "^githublike.common.* (" | cut -d"." -f3- | cut -d"(" -f1)
  for function in $functions
  do
    eval """function backend.$backend.$function {
      githublike.common.$function \"\$@\"
    }"
  done
}

githublike.with() {
  githublike_issuemap=$(nux.cfg.dir.global)/${githublike_wrapper}.issuemap.json
}
