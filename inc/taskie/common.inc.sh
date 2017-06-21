

taskie.issue.display.short() {
  local id="$1";
  local state="$2";
  shift;
  shift;
  echo -n "$id ";
  taskie.state.colorized "$state" " ";
  for arg in "$@"
  do
    local before="";
    local after="";
    if [[ "$arg" =~ "#" ]]; then
      taskie.label.colorized "$arg" " "
    else
      echo -n "$arg"
    fi
  done
  echo
}

taskie.colorized() {
  local color_path="$1"
  local message="$2"
  local afterMessage="$3"
  local before=""
  local after=""
  color=$(nux.cfg.read colors.$color_path)
  if [ -n "$color" ]; then
    color_var="nc_$color"
    if [ -n "${!color_var}" ]; then
      before=${!color_var}
      after=$nc_end
    fi
  fi
  echo -n "${before}${message}${after}${afterMessage}"
}

taskie.state.colorized() {
  taskie.colorized state.$1 "$1" "$2"
}

taskie.label.colorized() {
  local label=${1#"#"}
  taskie.colorized labels.$label "$1" "$2"

}
