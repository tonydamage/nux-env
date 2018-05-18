#!/usr/bin/env bash

## nulang - NUX Custom DSL Support Library
##
## # Language Definition
##
## Language is defined in terms of BASH REGEX matches and functions that  process
## or execute particular match.

NUDSL_CACHE_SUFFIX=".nux.dsl.sh"

nux.dsl.eval() {
  $nudsl_eval "$@"
}

nux.dsl.env() {
  .process.highlight() {
    echo "$line";
  }
  .match._unmatched.highlight() {
    echo "${_gen_highlight_unmatched}$line${nc_end}"
  }

  .gen.parser._unmatched.process() {
    nux.exec.or .match._unmatched.$action .process.$action
  }

  .highlight() {
    nux.dsl.eval _gen_highlight_$1='$nc_'$2
  }
  .match() {
    local type=$1;
    local pattern=$2;
    shift; shift;
    i=0;
    local parse_body="";
    nux.dsl.eval _gen_parser_types='"$_gen_parser_types '$type'"'
    nux.dsl.eval _gen_parser_pattern_$type="'"$pattern"'"
    nux.dsl.eval """.gen.parser.$type.process() {
      $(
        for group in "$@"; do
          let i=$i+1;
          if [ "$group" !=  "-" ]; then
            echo local ${group}='${BASH_REMATCH['$i']}'
          fi
        done
      )
      nux.exec.or .match.$type.\$action .process.\$action
    }
    """

    nux.dsl.eval """.match.$type.highlight() {
      $(
        for group in "$@"; do
          let i=$i+1;
          if [ "$group" !=  "-" ]; then
            echo '  echo -n "${_gen_highlight_'$group'}$'$group'${nc_end}"'
          fi
        done
      )
        echo;
      }
    """

  }
}

nudsl_eval=eval

nux.dsl.process() {
  local action=$1;
  local language=$2;
  local file=$3;
  (
     nux.dsl.env
     $language
     cat "$file" | nux.dsl.process0 $action)

}

nux.dsl.exec() {
  local language="$1";
  local file="$2";
  local cached="${3:-$file${NUDSL_CACHE_SUFFIX}}";
  #FIXME: Add no-cache
  if nux.dsl.plan "$language" "$file" "$cached"; then
    source "$cached";
  fi
}

nux.dsl.plan.file() {
  local language="$1"
  local file="$2";
  echo "$file${NUDSL_CACHE_SUFFIX}";
}

nux.dsl.plan() {
  local language="$1";
  local file="$2";
  local cached="${3:-$file${NUDSL_CACHE_SUFFIX}}";
  if [ "$file" -ot "$cached" ]; then
    nux.log debug No need to recompile.
    return;
  fi

  nux.log debug Needs regeneration, creating new version.

  local dirname=$(dirname "$cached")
  mkdir -p "$dirname";
  local execution_plan=$(mktemp "$dirname/.nux.dsl.XXXX")
  if (nux.dsl.process plan "$language" "$file" > "$execution_plan") ; then
    mv -f "$execution_plan" "$cached";
  else
    echo "Plan could not be generated. See errors."
    rm "$execution_plan"
    return -1;
  fi
}

nux.dsl.process.fail() {
  process_failed=true
  echo "$linenum:$@" >&2
}

nux.dsl.process0() {
  local _gen_parser_pattern__unmatched='(.*)';
  local patterns="$_gen_parser_types _unmatched";
  local linenum=0;
  while IFS= read -r line ;
  do
    let linenum=$linenum+1
    for t in $patterns; do
      local pattern=_gen_parser_pattern_$t
      if [[ "$line" =~ ${!pattern} ]]; then
        .gen.parser.$t.process
        break;
      fi
    done
    if [ -n "$process_failed" ]; then
      return -1;
    fi
  done;
}
