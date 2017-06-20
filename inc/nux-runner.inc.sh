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
  command="$1"
  nux.log trace "Displaying help command for: $command"
  if [ -z $command ] ; then
    echo Usage: $NC_Bold$NUX_SCRIPTNAME ${NC_No}${NC_White}\<command\>${NC_No} [\<options\>]
    nux.help.comment "$NUX_SCRIPT"
    nux.help.comment "$NUX_RUNNER"
    nux.exec.optional task.help.additional
  elif nux.check.function "task.help.$command" ; then
    shift;
    task.help.$command "$@";
  else
    nuxr.help.task.comment "$NUX_SCRIPT" "$command" \
      || nuxr.help.task.comment "$NUX_RUNNER" "$command" \
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
