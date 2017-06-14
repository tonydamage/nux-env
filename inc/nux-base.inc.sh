## #nux-base - NUX Script Base library
##



readonly NUX_INC_DIR=$(dirname $(realpath  ${BASH_SOURCE[0]}))
readonly NUX_ENV_DIR=$(dirname $NUX_INC_DIR)

# Color definitions

readonly nc_bold=`tput setaf 0`
readonly nc_bg_bold=`tput setab 0`
readonly nc_black=`tput setab 0`
readonly nc_bg_black=`tput setab 0`
readonly nc_cyan=`tput setaf 6`
readonly nc_bg_cyan=`tput setab 6`
readonly nc_magenta=`tput setaf 5`
readonly nc_bg_magenta=`tput setab 5`
readonly nc_red=`tput setaf 1`
readonly nc_bg_red=`tput setab 1`
readonly nc_white=`tput setaf 7`
readonly nc_bg_white=`tput setab 7`
readonly nc_green=`tput setaf 2`
readonly nc_bg_green=`tput setab 2`
readonly nc_yellow=`tput setaf 3`
readonly nc_bg_yellow=`tput setab 3`
readonly nc_blue=`tput setaf 4`
readonly nc_bg_blue=`tput setab 4`
readonly nc_end=`tput sgr0`

readonly NC_Bold=`tput bold`
readonly NC_No=`tput sgr0` # No Color
readonly NC_Black='\033[0;30m'
readonly NC_Green='\033[0;32m'
readonly NC_Red=$nc_bold$nc_red
readonly NC_BrownOrange='\033[0;33m'
readonly NC_Blue='\033[0;34m'
readonly NC_Purple='\033[0;35m'
readonly NC_Cyan='\033[0;36m'
readonly NC_LightGray='\033[0;37m'
readonly NC_DarkGray='\033[1;30m'
readonly NC_LightRed='\033[1;31m'
readonly NC_LightGreen='\033[1;32m'
readonly NC_Yellow=$nc_yellow
readonly NC_LightBlue='\033[1;34m'
readonly NC_LightPurple='\033[1;35m'
readonly NC_LightCyan='\033[1;36m'
readonly NC_White=$nc_white

readonly NC_error=$NC_Red
## #Public functions:
##
## ##Logging

# Color for message levels
NC_LOG_color_info=$NC_LightGray
NC_LOG_color_error=$NC_LightRed
NC_LOG_color_warning=$NC_Yellow
NC_LOG_color_debug=$NC_White

NC_LOG_current=3

NC_LOG_id_none=0
NC_LOG_id_error=1
NC_LOG_id_warning=2
NC_LOG_id_info=3
NC_LOG_id_debug=4
NC_LOG_id_trace=5

##
## NUX Script environment provides basic logging capabilities.
##
## Currently there are 5 log levels supported (in order of detail):
##   error
##   warning
##   info
##   debug
##   trace
##
##   nux.log <level> <message>
##     Outputs log message to *STDERR*. LOG messages are filtered out based on
##     level. Use *nux.log.level* to specify which messages should be displayed.
##
##
function nux.log {
  local level=$1
  local message=$2
  local color=NC_LOG_color_$level
  local level_num=NC_LOG_id_$level
  shift;
  if [  ${!level_num} -le $NC_LOG_current  ]; then
    echo -e "${!color}[$level]$NC_No $*$NC_No" >&2
  fi
}


##   nux.log.level <level>
##     Sets maximum level of details to be logged.
##
function  nux.log.level {
  local level=$1
  local level_id=NC_LOG_id_$level
  NC_LOG_current=${!level_id}
}

function nux.echo.error {
	echo "${NC_error}$* ${NC_No}";
}

function nux.echo.warning {
	echo -e "${NC_warning}"$@" ${NC_No}";
}

##   nux.use <library>
##
function nux.use {
  local incfile="$1.inc.sh"
  source "$NUX_INC_DIR/$incfile"
}

function nux.fatal {
  echo "$@";
  exit -1;
}

##   nux.require <binary> [<common-package>]
function nux.require {
  local binary=$1;
  local package=${2:-$1}
  if nux.check.exec "$binary" ; then
    :
  else
    nux.fatal $1 is not present. Please check if $package is installed.
  fi

}

function nux.include {
  local incfile="$1.inc.sh"
  source "$NUX_INC_DIR/$incfile"
}

##   nux.check.function <name>
##
function nux.check.function {
  declare -f "$1" &>/dev/null && return 0
  return 1
}

function nux.check.exec {
  local binary=$1;
  test -n "$(which "$binary")"
}

##   nux.check.file.exists <name>
##
function nux.check.file.exists {
	test -e "$1" -o -h "$1";
}

function nux.eval {
  nux.log trace Going to evaluate "$@"
  eval "$@"
}

##   nux.exec.optional <name> [<arguments>]
##
function nux.exec.optional {
  local FUNC="$1"; shift;
  if nux.check.function $FUNC; then
    nux.log trace  Executing optional: ${NC_White}${FUNC}${NC_No} "$@";
    $FUNC "$@"
  fi
}

function nux.dirty.urlencode {
    echo -n "$1" | sed "s/ /%20/g"
}

function nux.help.comment {
  local source="$1"
  grep -E "^\#\#( |$)" "$source" \
    | cut -d\# -f3- \
    | cut -d" " -f2- \
    | nux.help.shelldoc

}

function nux.help.shelldoc {
  cat | sed -r \
    -e "s/^## ?(.*)/${NC_White}\1${NC_No}/gI" \
    -e "s/^# ?(.*)/${NC_Bold}\1${NC_No}/gI" \
    -e "s/^   ?[a-z0-9.-_]*/${NC_Bold}&${NC_No}/gI" \
    -e "s/\*\*([^*]*)\*\*/${NC_Bold}\1${NC_No}/gI"  \
    -e "s/\*([^*]*)\*/${NC_White}\1${NC_No}/gI"  \

}

NUX_ENV_MACHINE=/usr/
NUX_ENV_MACHINE_LOCAL=/usr/local/
NUX_ENV_USER_LOCAL=$HOME/.local
