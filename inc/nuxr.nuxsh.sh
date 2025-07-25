nux.use nux/color
nux.use nuxr/repl
nux.use nux/help

@prefix check nux.check.
@prefix help nux.help.

@namespace nuxr. {
  function :run TASK {
    # FIXME: Add default task
    if nux.check.function task.$TASK; then 
      nux.log debug  "Running task: $TASK";
      nux.log debug  "Working dir: $(pwd)"
      task.$TASK "$@" # Runs task
    elif nux.check.function nuxr.run.additional; then 
      nux.log debug  "Running additional task: $TASK";
      nuxr.run.additional "$TASK" "$@"
    else
      echo "$NUX_SCRIPTNAME: Unrecognized task  '$TASK' not available."
      echo "Try '$NUX_SCRIPTNAME help' for more information."
      return -1
    fi
  }

  function :run.subtask SUBTASK {
    if nux.check.function task.$TASK.$SUBTASK {
      nux.log debug  "Running subtask: $TASK";
      task.$TASK.$SUBTASK "$@" # Runs task
    else
      echo "$NUX_SCRIPTNAME: '$TASK' '$SUBTASK' not available."
      echo "Try '$NUX_SCRIPTNAME help' for more information."
    }
  }

  function :main {
    :run "$@"
  }
}

@namespace nuxr.task. {
  function :help {
    nuxr.task.help. "$@"
  }
### nuxr.task.interactive::
###   Runs an interactive taskie shell with base taskie commands available.
###
  function :interactive() {
    nux.use nux/repl
    nux.repl.start nuxr.repl.process nuxr.repl.prompt nuxr.repl.completer
  }

}

@namespace nuxr.task.help. {

  function : {
    allArgs="$@"
    if [ -z "$allArgs" ] {
      echo Usage: $NC_Bold$NUX_SCRIPTNAME ${NC_No}${NC_White}\<command\>${NC_No} [\<options\>]
      help:comment "$NUX_SCRIPT"
      help:comment "$NUX_RUNNER"
      nux.exec.optional task.help.additional
    else
      :topic "$@"
    }
  }

  ## nuxr.task.help.topic
  function :topic {
    first="$1"
    topic="$@"
    topic_dot=$(tr " " "." <<< $topic)
    nux.log trace "Displaying topic for: '$topic' '$topic_dot'"
    if check:function "task.help.$topic_dot" {
      shift;
      task.help.$topic "$@";
    elif nux.check.function "task.help.$first" ; then
      shift;
      task.help.$first "$@";
    else
      nuxr.task.help.comment "$NUX_SCRIPT" "$topic" \
        || nuxr.task.help.comment "$NUX_RUNNER" "$topic" \
        || echo "Help topic $1 not found. Run '$NUX_SCRIPTNAME help'  to see topics."
    }
  }

  function :comment script task {
    local task_dot=$(tr " " "." <<< "$task")
    nux.log trace "Trying to figure task documentation location for $task $task_dot"
    doc_start=$(grep -hn -E "## +($task)::" "$script" | cut -d: -f1)
    code_start=$(grep -hn -E "(@command +:?$task_dot)|(function +task.$task_dot)|(task.$task_dot *\(\) +{)" "$script" | cut -d: -f1)
    nux.log trace "doc_start" $doc_start $code_start
    if [ -n "$doc_start" -a -n "$code_start" ] {
      sed -n "$doc_start,$code_start"p "$script" \
        | grep "^##" \
        | sed -re "s/^#+ ?(.*)/\1/gi" \
        | nux.help.shelldoc
        return 0
      else
        return -1
    }
  }
}
