nux.use taskie/githublike
nux.use nux.json


githublike gogs

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
  gogs_api_token=$(gogs.config.site "$gogs_configId" .api.token)

  nux.log debug Gogs repository is $gogs_repository;
  nux.log debug Gogs API URL: $gogs_api_url;


  githublike_wrapper=gogs
  githublike_api=$(gogs.config.site "$gogs_configId" .api.url);
  githublike_repository=$gogs_repository;
  githublike_api_append="?token=$gogs_api_token";
  githublike_curl_params="";
  githublike_next_append="&token=$gogs_api_token";

  githublike.with
}
