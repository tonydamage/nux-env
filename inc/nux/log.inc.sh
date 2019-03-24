## ##Logging

# Color for message levels
NC_LOG_color_info=$NC_LightGray
NC_LOG_color_error=$NC_LightRed
NC_LOG_color_warning=$NC_Yellow
NC_LOG_color_debug=$NC_White

NC_LOG_current=${NC_LOG_current:=3}

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
## nux.log:: <level> <message>
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


## nux.log.level:: <level>
##     Sets maximum level of details to be logged.
##
function  nux.log.level {
  local level=$1
  local level_id=NC_LOG_id_$level
  NC_LOG_current=${!level_id}
}
