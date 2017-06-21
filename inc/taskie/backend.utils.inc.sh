
backend.githublike.get() {
  local api=$1;
  local append_next="$2";
  nux.log debug Repository is $gogs_repository, message is $message
  nux.log debug API call: $api Payload: $payload
  header_tmp=$(mktemp);
  while [ -n "$api" ];
  do
  curl $CURL_ADDITIONAL_ARGS -s -D "$header_tmp" -H "Content-Type: application/json" "$api"
  next=$(grep "Link: " "$header_tmp" | tr "," "\n" | grep rel=\"next\" | cut -d"<" -f2 | cut -d">" -f1)
  nux.log debug Next "$next";
  if [ -n "$next" ]; then
    api="${next}${append_next}"
  else
    api=""
  fi
  done;
  rm -f $header_tmp;
}
