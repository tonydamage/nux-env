nuxr.run() {
  TASK=$1; shift; # Determines task
  if [ -z "$NUX_NO_INCLUDE" ]
  then
  	nux.log debug  "Including script: $NUX_SCRIPT"
  	source $NUX_SCRIPT; # Includes script
  fi
  if nux.check.function task.$TASK ; then
    nux.log debug  "Running task: $TASK";
    task.$TASK "$@" # Runs task
  else
    echo "$NUX_SCRIPTNAME: Unrecognized task  ''$TASK' not available."
    echo "Try '$NUX_SCRIPTNAME help' for more information."
    exit -1
  fi
}

function nuxr.task.help {
  if [ -z "$@" ] ; then
    echo Usage: $NC_Bold$NUX_SCRIPTNAME ${NC_No}${NC_White}\<command\>${NC_No} [\<options\>]
    nux.help.comment "$NUX_SCRIPT"
    nux.help.comment "$NUX_RUNNER"
    nux.exec.optional task.help.additional
  else
    nuxr.task.help.topic "$@"
  fi
}

function nuxr.task.help.topic {
  topic="$1"
  nux.log trace "Displaying topic for: $topic"
  if nux.check.function "task.help.$topic" ; then
    shift;
    task.help.$topic "$@";
  else
    nuxr.help.task.comment "$NUX_SCRIPT" "$topic" \
      || nuxr.help.task.comment "$NUX_RUNNER" "$topic" \
      || echo "Help topic $1 not found. Run '$NUX_APPNAME help'  to see topics."
  fi
}

function nuxr.help.task.comment {
  local script="$1"
  local task="$2"

  nux.log trace "Trying to figure task documentation location for $@"
  doc_start=$(grep -hn -E "## +($task)::" "$script" | cut -d: -f1)
  code_start=$(grep -hn -E "((function +task.$task)|(task.$task *\(\))) +{" "$script" | cut -d: -f1)
  nux.log trace "doc_start" $doc_start $code_start
  if [ -n "$doc_start" -a -n "$code_start" ] ; then
    sed -n "$doc_start,$code_start"p "$script" \
      | grep "^\#\#" \
      | sed -re "s/^#+ ?(.*)/\1/gi" \
      | nux.help.shelldoc
    return 0
  else
    return -1
  fi
}

##
## nuxr.interactive::
##   Runs an interactive taskie shell with base taskie commands available.
##
nuxr.task.interactive() {
  nux.use nux.repl
  nux.repl.start nuxr.repl.process nuxr.repl.prompt nuxr.repl.completer
}


nuxr.repl.process() {
  backendFunc=task.$command;
  if nux.check.function repl.command.$command; then
    eval repl.command.$command "$arguments"
  elif nux.check.function task.$command; then
    eval nuxr.run "$command" "$arguments"
  else
    echo "$command" is not defined.
  fi
}

nuxr.repl.expose() {
  # FIXME: Figure different way of exposing direct functions without wrapping
  for cmd in "$@"; do
    eval """function repl.command.$cmd {
        $cmd "\$@"
    }
    """
  done
}
##
##  repl.command.::
##    fallback command which does nothing if user just presses enter.
##
repl.command.() {
  :
}

repl.command.help() {
  if [ -z "$@" ]  ;then
    echo "Usage: help [<command> | <topic>]"
    echo Displays help for specified topic or command.
    echo
    echo "${nc_white}Available topics:$nc_end"
    nuxr.tasks.runtime.search help.$current_word | cut -d"." -f2 | column
    echo
    echo "${nc_white}Available commands:$nc_end"
    nuxr.tasks.runtime.search $current_word | grep -v "help\\." | column
  else
    nuxr.task.help.topic "$@"
  fi
}

nuxr.repl.prompt() {
  echo "${nc_green}$NUX_APPNAME${nc_end}> "
}

nuxr.tasks.runtime.search() {
  set | grep -G "^task\.$1.* ()" \
  | cut -d "." -f2- \
  | cut -d"(" -f1
}

nuxr.repl.commands.search() {
  set | grep -E "^((repl\\.command)|(task))\\.$1.* ()" \
  | sed -re 's/^((repl\.command)|(task))\.//gi' \
  | cut -d"(" -f1 | sort | uniq

}

nuxr.repl.completer.help() {
    nux.log debug "Help completer"
    nux.log debug "current_pos $current_pos"
    nux.log debug "current word $current_word"
    if [ $current_pos -eq 2 ]; then
      nuxr.tasks.runtime.search $current_word | grep -v "help."
      nuxr.tasks.runtime.search help.$current_word | cut -d"." -f2
    fi
}

nuxr.repl.completer._prefix_task() {
  nux.log debug "Prefix completer. $current_pos $current_word"
  if [ $current_pos -eq 2 ]; then
    nuxr.tasks.runtime.search $current_word
  else
    nuxr.repl.completer "${line#$command }"
  fi
}

nuxr.repl.completer() {
  local line=$1;
  nux.log debug "Requested completion for " "'$line'"

  local words=($line)
  local current_pos=${#words[@]};
  local current_word="";
  if [ "$current_pos" -gt 0 ]; then
    current_word=${words[${#words[@]}-1]};
    if [ -n "$line" -a "$line" != "${line%% }" ] ; then
      nux.log debug "Creating proposal for next word."
      let current_pos=current_pos+1
      current_word=""
    fi
  fi
  local result="";
  if [ $current_pos -le 1 ] ; then
    result=$(nuxr.repl.commands.search $current_word | grep -v "help\\.")
  elif [ $current_pos -ge 2 ]; then
    command=${words[0]}
    nux.log debug "Trying to use completer for '$command'"
    case $command in
      debug) ;&
      trace)
        result=$(nuxr.repl.completer._prefix_task)
        ;;
      *)
        result=$(nux.exec.optional nuxr.repl.completer.$command)
        ;;
    esac;
  fi

  if [ -n "$result" ]; then
    nux.log debug "Completion found."
    echo $result
  else
    nux.log debug "No completion found."
    printf '\a' >> $(tty)
    if [ $current_pos -gt 1 ]; then
      echo $current_word
    fi
  fi
}

nux.app() {
  echo $NUX_APPNAME
}

nux.app.dir() {
    :
}
