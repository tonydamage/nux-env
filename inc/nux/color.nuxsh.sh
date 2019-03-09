if [ -t 1 ] {
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
}
