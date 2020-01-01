## ##Logging

# Color for message levels
if [ -t 1 ]; then
  NC_LOG_color_1='\033[1;31m'
  NC_LOG_color_2=`tput setaf 3`
  NC_LOG_color_3='\033[0;37m'
  NC_LOG_color_4=`tput setaf 7`
  NC_LOG_No=`tput sgr0`
fi


NC_LOG_id_none=0
NC_LOG_id_error=1
NC_LOG_id_warning=2
NC_LOG_id_warn=2
NC_LOG_id_info=3
NC_LOG_id_debug=4
NC_LOG_id_trace=5

NC_LOG_current=${NC_LOG_current:=3}



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
## nux.log:: <level> <message>
##     Outputs log message to *STDERR*. LOG messages are filtered out based on
##     level. Use *nux.log.level* to specify which messages should be displayed.
##
##
function nux.log {
  local level=$1
  local message=$2
  local level_num=NC_LOG_id_$level
  local color=NC_LOG_color_${!level_num}
  shift;
  if [  ${!level_num} -le $NC_LOG_current  ]; then
    echo -e "${!color}[$level]$NC_LOG_No $*$NC_LOG_No" >&2
  fi
}


## nux.log.level:: <level>
##     Sets maximum level of details to be logged.
##
function  nux.log.level {
  local level=$1
  local level_id=NC_LOG_id_$level
  NC_LOG_current=${!level_id}
}

if [ -n "$NUX_LOG_LEVEL" ]; then
  nux.log.level "$NUX_LOG_LEVEL";
fi

nux.log trace Nux Logger included
