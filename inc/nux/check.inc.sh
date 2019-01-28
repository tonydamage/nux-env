## nux.check.function:: <name>
##
function nux.check.function {
  nux.log trace "Checking if $1 is function."
  test "$(type -t "$1")" = "function" && return 0
  return 1

}

function nux.check.nuxenv.file {
  path=$(realpath -Lms "$1")
  [[ "$path" =~ "^$NUX_ENV_DIR" ]]
}


function nux.check.optional {
  local function="$1"; shift;
  if nux.check.function "$function" ; then
    $function "$@"
  fi
}

function nux.check.exec {
  local binary=$1;
  test -n "$(which "$binary")"
}

## nux.check.file.exists:: <name>
##
function nux.check.file.exists {
	test -e "$1" -o -h "$1";
}
