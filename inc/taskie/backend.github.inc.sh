backend.github.with() {
  github_repository=$(echo $backendId | cut -d: -f2)
  github_api_url=https://api.github.com
  github_api_user=$(nux.cfg.read github.user)
  github_api_token=$(nux.cfg.read github.api.token)
  github_issuemap=~/.config/taskie/github.issuemap.json
  nux.log debug Github repository is $github_repository;
  nux.log debug Github API URL: $github_api_url;
}

backend.github.list() {
  local api="$github_api_url/repos/$github_repository/issues"

  CURL_ADDITIONAL_ARGS="-u $github_api_user:$github_api_token" \
    backend.githublike.get "$api" | jq -r ".[] | [.number,.state,.title] | @sh"

}
