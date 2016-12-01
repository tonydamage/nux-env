

nux-runner.run() {
  TASK=$1; shift; # Determines task
  if nux.check.function task.$TASK 
  then
    nux.log debug  "Running task: $TASK";
    task.$TASK "$@" # Runs task
  else
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
  fi
}
