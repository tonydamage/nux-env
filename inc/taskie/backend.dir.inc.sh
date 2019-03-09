nux.log debug "Backend Dir loaded"

backend.dir.detect() {
  local dottaskie=$(nuxfs.closest .taskie "$1")
  local dottaskiedir=$(nuxfs.closest .taskie.self "$1")
  if [ -d "$dottaskie" ]; then
    echo "$dottaskie"
  elif [ -f "$dottaskie" -a "$(yaml r "$dottaskie" backend)" = "dir:self" ]; then
    dirname "$dottaskie"
  fi
}

backend.dir.with() {
  dir_repository=$(echo $backendId | cut -d: -f2)

}

backend.dir.labels() {
  find "$dir_repository" -type d | grep -v "^\." | grep -v "/\." |xargs -n1 realpath --relative-to="$dir_repository"
}
