

## nux.repl.start <processor> [<prompt>] [<complete>]
##   Starts NUX REPL
##
##   FIXME: Add autocompletion
function nux.repl.start {
  function .null() {
    :
  }
  local processor=$1;
  local prompt=${2:-.null};
  local complete=$3;
  local command=""

  if nux.check.function $complete; then
    bind -x '"\C-i": "nux.repl.completion $prompt $complete"' &> /dev/null
  fi

  while IFS=" " read -e -p "$($prompt)" options
  do
    history -s "$options" > /dev/null 2>&1
    nux.log debug Readed line is: $nc_white$options$nc_end
    command=$(echo $options | cut -d" " -f1)
    arguments=${options#"$command"}
    nux.log debug Command: $command, arguments: $arguments
    case "$command" in
      exit)
        break;;
      *)
        $processor $command $arguments
        ;;
    esac
  done
}

## nux.repl.completion <prompt> <completion>
##
##
## This function is modified version of
## https://github.com/mchav/with/blob/master/with

function nux.repl.completion() {
  local prompt=$1;
  local compgen_command=$2;
  shift;shift;
  # print readline's prompt for visual separation
  if [ "$#" -eq 0 ]; then
      echo "$($prompt)$READLINE_LINE"
  fi

  pmpt=$($prompt)
  # remove part after readline cursor from completion line
  local completion_line completion_word
  completion_line="${READLINE_LINE:0:READLINE_POINT}"
  completion_word="${completion_line##* }"

  # set completion cursor according to pmpt length
  COMP_POINT=$((${#pmpt}+${#completion_line}+1))
  COMP_WORDBREAKS="\n\"'><=;|&(:"
  COMP_LINE="$pmpt $completion_line"
  # TODO: the purpose of these variables is still unclear
  # COMP_TYPE=63
  # COMP_KEY=9

  # get index of word to be completed
  local whitespaces_count escaped_whitespaces_count
  whitespaces_count=$(echo "$COMP_LINE" | grep -o ' ' | wc -l)
  escaped_whitespaces_count=$(echo "$COMP_LINE" | grep -o '\\ ' | wc -l)
  COMP_CWORD=$((whitespaces_count-escaped_whitespaces_count))

  # get sourced completion command
  local program_name complete_command
  program_name=${COMP_WORDS[0]}
  program_name=$(basename "$program_name")
  complete_command=$(complete -p | grep " ${program_name}$")

  COMPREPLY=()
  COMPREPLY=($($compgen_command "$completion_line"))

  # get commmon prefix of available completions
  local completions_prefix readline_prefix readline_suffix
  completions_prefix=$(printf "%s\n" "${COMPREPLY[@]}" | \
    sed -e '$!{N;s/^\(.*\).*\n\1.*$/\1\n\1/;D;}' | xargs)
  readline_prefix="${READLINE_LINE:0:READLINE_POINT}"
  readline_suffix="${READLINE_LINE:READLINE_POINT}"
  # remove the word to be completed
  readline_prefix=$(sed s/'\w*$'// <(echo "$readline_prefix") | xargs)

  READLINE_LINE=""
  if [[ "$readline_prefix" != "" ]]; then
    READLINE_LINE="$readline_prefix "
  fi

  READLINE_LINE="$READLINE_LINE$completions_prefix"
  # adjust readline cursor position
  READLINE_POINT=$((${#READLINE_LINE}+1))

  if [[ "$readline_suffix" != "" ]]; then
    READLINE_LINE="$READLINE_LINE $readline_suffix"
  fi

  local completions_count display_all
  completions_count=${#COMPREPLY[@]}
  display_all="y"
  if [[ $completions_count -eq 1 ]]; then
    READLINE_LINE=$(echo "$READLINE_LINE" | xargs)
    READLINE_LINE="$READLINE_LINE "
    return
  elif [[ $completions_count -gt 80 ]]; then
    echo -en "Display all $completions_count possibilities? (y or n) "
    read -N 1 display_all
    echo "$display_all"
  fi

  if [[ "$display_all" = "y" ]]; then
    for completion in "${COMPREPLY[@]}"; do echo "$completion"; done | column
  fi
}
