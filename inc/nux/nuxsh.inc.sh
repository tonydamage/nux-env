nux.use nux/dsl

nux.nuxsh.language.def() {
  local identifier_char='[^ ;{}=()$:]'
  local identifier='[^ ;{}=()$:]+'
  local comment='(( *)(#.*))?'
  local whitespace="([ ]*)"
  local uarg="([^ #{}\"'\"'\"';]+)";
  local sarg="('\"'\"'[^'\"'\"']+'\"'\"')";
  local darg='("[^"]*")';

  local args="((($uarg|$darg|$sarg) *)*)";

  local prefixed_id="($identifier_char*:)?($identifier)"

  .match.line() {
    local type="$1";
    local match="^( *)$2$comment$";
    shift;shift;
    .match "$type" "$match" indent "$@" - indent_comment comment;
  }

  .match.line comment ''
  .match.line rule "(@)([^ ]+)( +)$args?( *);?"\
      syntaxM rule indent2 args - - - - - indent3 syntax2

  .match.line namespace_block_start "(@)(namespace)(( +)$uarg)( *)(\{)" \
     syntaxM keyword - indent2 identifier indent3 syntax3
  #.match.line namespace_start "@(namespace)( +)$uarg( *)(\{)" \
  #        namespace indent2 args indent3 syntax
  .match.line block_end '(\})' \
      syntax


  .match.line if_start "(if)( +)$prefixed_id( +)$args?( *)(\{)" \
          keyword indent2 prefix identifier indent3 args - - - - - indent4 syntax3

  .match.line function_start "((function)( +))(:?$identifier)((\()|( *))(($identifier,? *)*)(\))?( *)(\{)" \
      - keyword indent2 identifier - syntax indent3 args - syntax2 indent4 syntax3

  .match.line block_start "$prefixed_id(( +)$args)?( *)(\{)" \
      prefix identifier - indent2 args - - - - - indent3 syntax3

  .match.line statement "$prefixed_id(( +)$args)?( *)(;?)"\
      prefix identifier - indent2 args - - - - - indent3 syntax2

  #.match.line variable "([^ ]+=)$args( *)(;?)"\
  #        variable args - - - - - indent3 syntax

  .highlight rule cyan
  .highlight syntaxM cyan

  .highlight prefix cyan
  .highlight identifier green
  .highlight keyword blue
  .highlight args yellow

  .highlight comment magenta

  .highlight unmatched red

  .highlight syntax white
  .highlight syntax2 white
  .highlight syntax3 white

  blocktrac_root="#blocktrac_root"
  _block_type[${#_block_type[@]}]="$blocktrac_root"

  function .block.get {
    echo ${_block_type[${#_block_type[@]}-1]}
  }

  function .block.args.get {
    echo ${_block_args[${#_block_args[@]}-1]}
  }

  function .block.pop {
    unset _block_type[${#_block_type[@]}-1]
    unset _block_args[${#_block_args[@]}-1]
  }

  function .block.push {
    local block="$1";shift;
    _block_type[${#_block_type[@]}]="$block"
    _block_args[${#_block_args[@]}]="$@"
  }

  .match.block_start.plan() {
    nux.log debug "P '$identifier' '$prefix' "
    local identifier=$(.identifier)
    nux.log debug "Block '$identifier' '$prefix' "
    .block.push "$identifier" "$args";
    nux.exec.or .block.$identifier.start.plan .block.start.plan
  }

  .match.block_end.plan() {
    local identifier=$(.block.get)
    if [ "$identifier" == "$blocktrac_root" ]; then
      nux.dsl.process.fail "unnecessary block end '$line' "
      return 1;
    fi
    nux.exec.or .block.$identifier.end.plan .block.end.plan
    .block.pop;
  }

  .action.alias() {
    local alias=$1; shift;
    echo "# alias: $alias $@";
    eval "_alias_$alias='$@'";
  }

  .action.prefix() {
    echo "# prefix: $1 ${2%.}"
    eval "_import_prefix_$1='${2%.}'";
  }


  .identifier() {
    if [ -n "$prefix" ]; then
      local var=_import_prefix_${prefix%:}
      local prepend=${!var};
      if [ -z "$prepend" ] ; then
        nux.dsl.process.fail "undefined prefix: $prefix";
        return;
      fi
      echo "$prepend.$identifier"
    else
      cat <<< "$identifier"
    fi
  }


  .match.statement.plan() {
    identifier=$(.identifier);
    nux.exec.or .statement.$identifier.plan .statement.plan

  }

  .statement.plan() {
    echo "${indent}$identifier ${args}"
  }
  .match.rule.plan() {
    echo "rule " >&2;
    eval ".action.${rule//:/.} $args";
  }

  .process.plan() {
    echo "$line";
  }


  .match.if_start.plan() {
    .block.push lang.if;
    echo "${indent}${keyword} $(.identifier) ${args} ; then"
  }

  .block.lang.if.end.plan() {
    echo "${indent}fi";
  }

  .match.namespace_block_start.plan() {
    .block.push rule.namespace;
    echo "# namespace $identifier"
    _namespace="$identifier"
    _import_prefix_="$identifier"
  }

  .block.rule.namespace.end.plan() {
    _namespace=""
    _import_prefix_=""
    echo "#namespace end"
  }

  .match.function_start.plan() {
    .block.push function
    case $identifier in
      :)  identifier="$_namespace";;
      :*) identifier="$_namespace.${identifier#:}";;
    esac;
    echo "${indent}$identifier() {";
     for arg in ${args//,/ }; do
       echo "${indent}  local $arg="'"$1"'";shift;"
     done
  }

  .block.start.plan() {
    case $identifier in
      function) echo "$line";;
      *"()") echo "$line";;
      *) nux.dsl.process.fail Invalid block syntax: "'$identifier' '$line'";
    esac;
  }

  .block.end.plan() {
    .process.plan;
  }

  .do.function.prefix() {
    echo "${indent}function $1$args {"
  }

  .action.block.rewrite.function.prefix() {
      echo "# block:rewrite:function:prefix $@"
      eval """.block.$1.start.plan() {
        .do.function.prefix "$2"
      }
      """
  }

  .action.syntax() {
    nux.use "$1.syntax"
  }

  .action.block.rewrite.call() {
    echo "# block:rewrite:block:call $@"
    eval """.block.$1.start.plan() {
      echo \"\${indent}\"'${2}'\" \$args\"'${3}'
    }

    .block.$1.end.plan() {
      echo \"\${indent}\"'${4}'
    }
    """
  }

  .action.block.rewrite.call2() {
    echo "# block:rewrite:block:call2 $@"
    nux.nuxsh.block.rewrite.call "$1" "$2" "$3"
  }

}

nux.nuxsh.block.rewrite.call() {
  eval """.block.$1.start.plan() {
    echo \"\${indent}\"'${2}'\" \$args\"
  }

  .block.$1.end.plan() {
    local args=\"\$(.block.args.get)\";
    echo \"\${indent}\"'${3}' \"\$args\"
  }
  """
}

nux.nuxsh.block.rewrite.func() {
  eval """
    .block.$1.start.plan() {
       ${2} \"\${indent}\" \"\$args\"
    }
    .block.$1.end.plan() {
      ${3} \"\${indent}\" \"\$args\"
    }
  """
}

nux.nuxsh.statement.rewrite.func() {
  eval """
    .statement.$1.plan() {
       ${2} \"\${indent}\" \"\$args\"
    }
    """
}

nux.nuxsh.statement.rewrite.call() {
  eval """.statement.$1.plan() {
    nux.nuxsh.statement.rewrite.call0 '$2' '$3'
  }
  """
}
nux.nuxsh.statement.rewrite.call0() {
  echo "${indent}${1} $args ${2}"
}


function nux.nuxsh.use {
	local file="$1";
  local cached="$2";
	nux.dsl.exec nux.nuxsh.language.def "$file" "$cached"
}
