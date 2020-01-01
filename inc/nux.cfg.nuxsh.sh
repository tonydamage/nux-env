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
##  - value is tried to be read first from *local*, then *global*, then *dist*
##    configuration.
##
## #Usage
##
## Basic usage of nux.cfg is really simple:
##    - use *:read* function to read configuration value
##    - use *:write* to write configuration value.
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

@namespace nux.cfg. {

## :read:: [<store>] <path>
##   Reads configuration value stored at *path* from specified *store*.
##   If no store is specified returns first found value in all stores
##   in following order *local, global, dist*.
##
function :read {
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

## :write::  <global | local> <path> <value>
##   Writes specified value to *global* or *local* store.
##   If configuration file does not exists, it creates it.
##
  function :write store {
    nux.log trace "Store is: $store";
    case $store in
      global ) ;;
      local ) ;;
      dist )
        nux.fatal "Write to dist store is disabled."
        ;;
      * )
        nux.fatal "Unknown config store $store".
        ;;
    esac
    shift;
    :write.direct "$(nux.cfg.file.$store)" "$@"
  }

## :dir.global::
##   Returns path of *global* config directory. May be overriden
##   by library for customization of path format.
##
  function :dir.global {
    echo "$HOME/.config/$NUX_APP_NAME"
  }
## :dir.dist::
##   Returns path of *dist* config directory. SHOULD be overriden
##   by library for customization of path format.

  function :dir.dist {
    echo "$NUX_APP_DIR/config/$NUX_APP_NAME"
  }
## :dir.local::
##   Returns path of *local* config directory. SHOULD be overriden
##   by library for customization of path format.
##
  function :dir.local {
    :dir.global
  }

## :file.global::
## :file.local::
## :file.dist::
##   Returns path of *global* config file. Default implementation appends
##   *config.yaml* to the respective path. May be overriden if main config
##   file is determined in different way.
##
  function :file.global {
    echo $(nux.cfg.dir.global)/$nux_cfg_config_file
  }

  function :file.dist {
    echo $(nux.cfg.dir.dist)/$nux_cfg_config_file
  }

  function :file.local {
    echo $(nux.cfg.dir.local)/$nux_cfg_config_file
  }

  function :read.direct {
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



  function :write.direct file {
    if ! nux.check.file.exists "$file" ; then
      mkdir -p "$(dirname "$file")";
      touch "$file";
    fi
    shift;
    yaml w "$file" "$@" -i
  }



  function :get.path {
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

}
