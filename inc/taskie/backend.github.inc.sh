nux.use taskie/githublike

githublike github


backend.github.with() {
  github_repository=$(echo $backendId | cut -d: -f2)
  github_api_url=https://api.github.com
  github_api_user=$(nux.cfg.read github.user)
  github_api_token=$(nux.cfg.read github.api.token)
  github_issuemap=~/.config/taskie/github.issuemap.json
  nux.log debug Github repository is $github_repository;
  nux.log debug Github API URL: $github_api_url;

  githublike_wrapper=github
  githublike_api=$github_api_url;
  githublike_repository=$github_repository;
  githublike_api_append="";
  githublike_curl_params="-u $github_api_user:$github_api_token";
  githublike_next_append="";
  githublike.with
}

backend.github.detect() {
  closest_git=$(nuxfs.closest .git "$1")

  git.origins "$closest_git" | grep github.com | while read origin
  do
    repo=$(nux.url.parse "$origin" "\9")
    echo $repo:$closest_git
  done
}

backend.github.labels.id() {
  githublike.get "labels" \
   | jq -r ".[] | .name + \":\" + .name"
}
