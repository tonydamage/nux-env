
readonly NUX_INC_DIR=$(dirname $(realpath  ${BASH_SOURCE[0]}))
readonly NUX_ENV_DIR=$(dirname $NUX_INC_DIR)

# Color defintions

readonly NC_No='\033[0m' # No Color
readonly NC_Black='\033[0;30m'
readonly NC_Green='\033[0;32m'
readonly NC_Red='\033[0;31m'
readonly NC_BrownOrange='\033[0;33m'
readonly NC_Blue='\033[0;34m'
readonly NC_Purple='\033[0;35m'
readonly NC_Cyan='\033[0;36m'
readonly NC_LightGray='\033[0;37m'
readonly NC_DarkGray='\033[1;30m'
readonly NC_LightRed='\033[1;31m'
readonly NC_LightGreen='\033[1;32m'
readonly NC_Yellow='\033[1;33m'
readonly NC_LightBlue='\033[1;34m'
readonly NC_LightPurple='\033[1;35m'
readonly NC_LightCyan='\033[1;36m'
readonly NC_White='\033[1;37m'

# Color for message levels
NC_info=$NC_LightGray
NC_error=$NC_LightRed
NC_warning=$NC_Yellow
NC_debug=$NC_White

N_LOG_info=1
N_LOG_error=2
N_LOG_warning=3

function nux.log {
  local level=$1
  local color=NC_$level
  local setting=N_LOG_$level
  shift;
  if [ ! -z ${!setting+x} ]; then
    echo -e "${!color}[$level]$NC_No $*$NC_No" >&2
  fi
}

function nux.echo.error {
	echo -e "${NC_error}$* ${NC_No}";
}

function nux.echo.warning {
	echo -e "${NC_warning}$* ${NC_No}";
}


function nux.include {
  local incfile="$1.inc.sh"
  source "$NUX_INC_DIR/$incfile"
}

function nux.check.function {
  declare -f "$1" &>/dev/null && return 0
  return 1
}
