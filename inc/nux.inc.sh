## #nux-base - NUX Script Base library

readonly NUX_INC_DIR=$(dirname $(realpath  ${BASH_SOURCE[0]}))
readonly NUX_ENV_DIR=$(dirname $NUX_INC_DIR)
readonly NUX_CACHE_DIR="$NUX_ENV_DIR/cache"

source "$NUX_INC_DIR/nux/log.inc.sh"

# Color definitions



## #Public functions:
##

function nux.echo.error {
	echo "${NC_error}$* ${NC_No}";
}

function nux.echo.warning {
	echo -e "${NC_warning}"$@" ${NC_No}";
}

function nux.fatal {
  echo "$@";
  exit -1;
}

## nux.notimplemented:: <feature-id>
function nux.notimplemented {
  nux.fatal "$@: is not imlemented."
}

## nux.require:: <binary> [<common-package>]
function nux.require {
  local binary=$1;
  local package=${2:-$1}
  if nux.check.exec "$binary" ; then
    :
  else
    nux.fatal $1 is not present. Please check if $package is installed.
  fi

}

## nux.use:: <library>
function nux.use {
	nux.log trace "nux.use: Including: $1"
  local incfile="$1.inc.sh"
	local nuxshfile="$1.nuxsh.sh"
	#FIXME: Do not use same file twice.
	if [ -e "$NUX_INC_DIR/$incfile" ]; then
		source "$NUX_INC_DIR/$incfile";
	elif [ -e "$NUX_INC_DIR/$nuxshfile" ]; then
		nux.nuxsh.use "$NUX_INC_DIR/$nuxshfile" "$NUX_CACHE_DIR/inc/$incfile";
	else
		nux.fatal "$1 not available."
	fi
}

function nux.eval {
  nux.log trace Going to evaluate "$@"
  eval "$@"
}

## nux.exec.optional:: <name> [<arguments>]
##
function nux.exec.optional {
  local FUNC="$1"; shift;
  if nux.check.function $FUNC; then
    nux.log trace  Executing optional: ${NC_White}${FUNC}${NC_No} "$@";
    $FUNC "$@"
  fi
}

function nux.exec.or {
  local maybe="$1"; shift;
  local to_exec="$1"; shift;
  if nux.check.function "$maybe" ; then
    to_exec=$maybe
  fi
  nux.log trace "Executing $to_exec , optional was $maybe"
  $to_exec "$@";
}


function nux.dirty.urlencode {
    echo -n "$1" | sed "s/ /%20/g"
}

function nux.url.parse {
  format=${2:-"protocol:\2\nuser:\4\nhost:\5\nport:\7 \npath:\8"}
  echo "$1" | sed \
    -re "s/(([^:\/]*):\/\/)?(([^@\/:]*)@)?([^:\/]+)(:([0-9]+))?(\/(.*))?/$format/g"

}

nux.use nux/check
nux.use nux/nuxsh
