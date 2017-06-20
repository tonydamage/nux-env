## #nux.cfg - NUX Script Configuration management library
##
## *nux.cfg* provides basic configuration management using yaml as configuration
## store and merging configuration from *local*, *global* and *dist* configuration.
##
## The configuration management library tries to have *sane defaults* (which
## are overrideable):
##
##  - configuration file is allways *config.yaml*
##  - configuration locations are (overrideable):
##    - *local* - by default same as global
##    - *global* - ~/.config/{app-name}/
##    - *dist* - {app-path}/config
##  - value is tried to be read first from *local*, then *global*, then *dist* configuration.
##
## #Usage
##
## Basic usage of nux.cfg is really simple:
##    - use *nux.cfg.read* function to read configuration value
##    - use *nux.cfg.write* to write configuration value.
##
## If you are using *nux-runner* for your scripts, it automaticly add *config*
## task which can be used by user to read / modify configuration values.
##
## For more advanced use see *Public functions* section describing each function.
##
##
nux_cfg_config_file=config.yaml

## #Public functions:
##


## nux.cfg.read:: [<store>] <path>
##   Reads configuration value stored at *path* from specified *store*.
##   If no store is specified returns first found value in all stores
##   in following order *local, global, dist*.
##
function nux.cfg.read {
  nux.log trace "Reading configuration $@"
  maybe_store="$1";
  local read_from="local global dist"
  case "$maybe_store" in
    global ) ;&
    local ) ;&
    dist )
      shift;
      read_from=$maybe_store
      ;;
    * ) ;;
  esac
  nux.log trace "Reading from $read_from"
  for store in $read_from ; do
    value=$(nux.cfg.read.direct "$(nux.cfg.file.$store)" "$@")
    if [ -n "$value" ] ; then
      echo $value;
      break;
    fi
  done

}

## nux.cfg.write::  <global | local> <path> <value>
##   Writes specified value to *global* or *local* store.
##   If configuration file does not exists, it creates it.
##
function nux.cfg.write {
  store="$1";
  nux.log trace "Store is: $1";
  case $store in
    global ) ;;
    local ) ;;
    dist )
      nux.fatal "Write to dist store is disabled."
      ;;
    * )
      nux.fatal "Unknown config store $1".
      ;;
  esac
  shift;
  nux.cfg.write.direct "$(nux.cfg.file.$store)" "$@"
}

## nux.cfg.dir.global::
##   Returns path of *global* config directory. May be overriden
##   by library for customization of path format.
##
function nux.cfg.dir.global {
  echo "$HOME/.config/$NUX_APPNAME"
}
## nux.cfg.dir.dist::
##   Returns path of *dist* config directory. SHOULD be overriden
##   by library for customization of path format.

function nux.cfg.dir.dist {
  echo "$NUX_ENV_DIR/config/$NUX_APPNAME"
}
## nux.cfg.dir.local::
##   Returns path of *local* config directory. SHOULD be overriden
##   by library for customization of path format.
##
function nux.cfg.dir.local {
  nux.cfg.dir.global
}

## nux.cfg.file.global::
## nux.cfg.file.local::
## nux.cfg.file.dist::
##   Returns path of *global* config file. Default implementation appends
##   *config.yaml* to the respective path. May be overriden if main config
##   file is determined in different way.
##
function nux.cfg.file.global {
  echo $(nux.cfg.dir.global)/$nux_cfg_config_file
}

function nux.cfg.file.dist {
  echo $(nux.cfg.dir.dist)/$nux_cfg_config_file
}

function nux.cfg.file.local {
  echo $(nux.cfg.dir.local)/$nux_cfg_config_file
}

function nux.cfg.read.direct {
  local file="$1";shift
  nux.log trace "Direct read from $file";
  local path="$@";
  if nux.check.file.exists "$file"; then
    if [ -n "$path" ]; then
      value=$(yaml r  "$file" "$path")
      if [ "$value" != null ]; then
        echo "$value"
      fi
    else
      cat "$file";
    fi
  fi
}



function nux.cfg.write.direct {
  file="$1";
  if ! nux.check.file.exists "$1" ; then
    mkdir -p "$(dirname "$file")";
    touch "$file";
  fi
  shift;
  yaml w "$file" "$@" -i
}



function nux.cfg.get.path {
  nux.log trace "Reading configuration $@"
  local only_first=""
  if [ "$1" = "--first" ]; then
    only_first="$1"; shift;
  fi

  maybe_store="$1";
  local read_from="local global dist"
  case "$maybe_store" in
    global ) ;&
    local ) ;&
    dist )
      shift;
      read_from=$maybe_store
      ;;
    * ) ;;
  esac
  nux.log trace "Reading from $read_from"
  for store in $read_from ; do
    path="$(nux.cfg.dir.$store)/$@"
    nux.log trace "Testing $path"
    if [ -e "$path" ] ; then
      echo $path;
      if [ -n "$only_first" ]; then
        break;
      fi
    fi
  done
}
