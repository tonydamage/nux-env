nux.use nux/dsl

nux.nuxsh.language.def() {
  local identifier='[^ ;{}=()$]+'
  local comment='(( *)(#.*))?'
  local whitespace="([ ]*)"
  local uarg="([^ #\{\}\"'\"'\"';]+)";
  local sarg="('\"'\"'[^'\"'\"']+'\"'\"')";
  local darg='("[^"]*")';

  local args="((($uarg|$darg|$sarg) *)*)";

  local prefixed_id="([^= :]*:)?($identifier)"

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


  .match.line task_start "((@command)( +))($identifier)((\()|( *))(($identifier,? *)*)(\))?( *)(\{)" \
      - keyword indent2 identifier - syntax indent3 args - syntax2 indent4 syntax3


  .match.line function_start "((function)( +))($identifier)((\()|( *))(($identifier,? *)*)(\))?( *)(\{)" \
      - keyword indent2 identifier - syntax indent3 args - syntax2 indent4 syntax3



  .match.line block_start "($identifier)(( +)$args)?( *)(\{)" \
      identifier - indent2 args - - - - - indent3 syntax3

  .match.line statement "$prefixed_id(( +)$args)?( *)(;?)"\
      prefix identifier - indent2 args - - - - - indent3 syntax2

  #.match.line variable "([^ ]+=)$args( *)(;?)"\
  #        variable args - - - - - indent3 syntax

  .highlight rule cyan
  .highlight syntaxM cyan

  .highlight prefix cyan
  .highlight identifier green
  .highlight keyword cyan
  .highlight args yellow

  .highlight comment magenta

  .highlight unmatched white

  .highlight syntax white
  .highlight syntax2 white
  .highlight syntax3 white

  blocktrac_root="#blocktrac_root"
  _block_type[${#_block_type[@]}]="$blocktrac_root"

  function .block.get {
    echo ${_block_type[${#_block_type[@]}-1]}
  }

  function .block.pop {
    unset _block_type[${#_block_type[@]}-1]
  }

  function .block.push {
    _block_type[${#_block_type[@]}]="$1"
  }

  .match.block_start.plan() {
    .block.push $identifier;
    nux.exec.or .block.$identifier.start.plan .block.start.plan
  }

  .match.block_end.plan() {
    local identifier=$(.block.get)
    if [ "$identifier" == "$blocktrac_root" ]; then
      nux.dsl.process.fail "unnecessary block end '$line' "
      return -1;
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
    echo "# prefix: $1 $2"
    eval "_import_prefix_$1='$2'";
  }


  .identifier() {
    if [ -n "$prefix" ]; then
      local var=_import_prefix_${prefix%:}
      local prepend;
      if [ -n "$var" ]; then
        prepend=${!var};
      else
        prepend=$_namespace;
      fi
      if [ -z "$prepend" ] ; then
        nux.dsl.process.fail "undefined prefix: $prefix";
      fi
      echo "$prepend$identifier"
    else
      echo "$identifier"
    fi
  }


  .match.statement.plan() {
    echo "${indent}$(.identifier) ${args}"
  }

  .match.rule.plan() {
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
      .*) ;;
      :*) identifier="$_namespace${identifier#:}"
    esac;
    echo "${indent}$identifier() {";
    echo "${indent}  nux.log trace $identifier: invoked";
     for arg in ${args//,/ }; do
       echo "${indent}  local $arg="'"$1"'";shift;"
       echo "${indent}  nux.log trace  '  ' arg $arg: "'$'$arg";"
       echo "${indent}  nux.log trace  '  ' rest: " '"$@";'
     done
  }

  .match.task_start.plan() {
    .block.push task
    case $identifier in
      :*) identifier="task.${identifier#:}";;
      *) identifier="task.$identifier"
    esac;
    echo "${indent}$identifier() {";
    echo "${indent}  nux.log trace $identifier: invoked";
     for arg in ${args//,/ }; do
       echo "${indent}  local $arg="'"$1"'";shift;"
       echo "${indent}  nux.log trace  '  ' arg $arg: "'$'$arg";"
       echo "${indent}  nux.log trace  '  ' rest: " '"$@";'
     done
  }

  .block.start.plan() {
    case $identifier in
      function) echo "$line";;
      *"()") echo "$line";;
      *) nudsl.process.fail Invalid block syntax: "'$identifier' '$line'";
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
}

function nux.nuxsh.use {
	local file="$1";
  local cached="$2";
	nux.dsl.exec nux.nuxsh.language.def "$file" "$cached"
}
