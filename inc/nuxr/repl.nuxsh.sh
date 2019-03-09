#
###
#
#
@namespace nuxr.repl {
  function :process {
    backendFunc=task.$command;
    if nux.check.function repl.command.$command; then
      eval repl.command.$command "$arguments"
    elif nux.check.function task.$command; then
      eval nuxr.run "$command" "$arguments"
    else
      echo "$command" is not defined.
    fi
  }

  function :expose {
    # FIXME: Figure different way of exposing direct functions without wrapping
    for cmd in "$@"; do
      eval "function repl.command.$cmd { $cmd \"\$@\"; }"
    done
  }

  function :prompt {
    echo "${nc_green}$NUX_APPNAME${nc_end}> "
  }

}

@namespace repl.command {
  ##
  ##  repl.command.::
  ##    fallback command which does nothing if user just presses enter.
  ##
  function : {
    echo >>/dev/null
  }

  function :help {
    if [ -z "$@" ]  ;then
      echo "Usage: help [<command> | <topic>]"
      echo Displays help for specified topic or command.
      echo
      echo "${nc_white}Available topics:$nc_end"
      :search.tasks help.$current_word | cut -d"." -f2 | column
      echo
      echo "${nc_white}Available commands:$nc_end"
      :search.tasks $current_word | grep -v "help\\." | column
    else
      nuxr.task.help.topic "$@"
    fi
  }

}


@namespace nuxr.repl.completer {

  function :search.tasks  {
    set | grep -G "^task\.$1.* ()" \
    | cut -d "." -f2- \
    | cut -d"(" -f1
  }


  function :search.commands {
    set | grep -E "^((repl\\.command)|(task))\\.$1.* ()" \
    | sed -re 's/^((repl\.command)|(task))\.//gi' \
    | cut -d"(" -f1 | sort | uniq
  }

  function :help() {
      nux.log debug "Help completer"
      nux.log debug "current_pos $current_pos"
      nux.log debug "current word $current_word"
      if [ $current_pos -eq 2 ]; then
        :search.tasks $current_word | grep -v "help."
        :search.tasks help.$current_word | cut -d"." -f2
      fi
    }

    function :_prefix_task() {
      nux.log debug "Prefix completer. $current_pos $current_word"
      if [ $current_pos -eq 2 ]; then
        :search.tasks $current_word
      else
        nuxr.repl.completer "${line#$command }"
      fi
    }

    function nuxr.repl.completer {
      local line=$1;
      nux.log debug "Requested completion for " "'$line'"

      local words=($line)
      local current_pos="${#words[@]}";
      local current_word="";
      if [ "$current_pos" -gt 0 ]; then
        current_word="${words[${#words[@]}-1]}";
        if [ -n "$line" -a "$line" != "${line%% }" ] ; then
          nux.log debug "Creating proposal for next word."
          let current_pos=current_pos+1
          current_word=""
        fi
      fi
      local result="";
      if [ $current_pos -le 1 ] ; then
        result=$(nuxr.repl.completer.search.commands $current_word | grep -v "help\\.")
      elif [ $current_pos -ge 2 ]; then
        command="${words[0]}"
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
}
