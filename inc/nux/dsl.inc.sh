#!/usr/bin/env bash

## nux.dsl - NUX Custom DSL Support Library
##
## Core DSL engine providing regex-based line-by-line language parsing with
## compilation caching. Languages are defined in terms of bash regex patterns
## and callback functions that transform matching lines.
##
## The engine supports two modes:
##   plan::
##     Generates transformed output text (compilation).
##   process::
##     Passes through matched lines unchanged (default highlighting).
##
## # Language Definition
##
## Language is defined in terms of BASH REGEX matches and functions that
## process or execute particular match. A language function calls `.match`
## to register patterns, each of which defines a regex, variable assignments,
## a plan function, and a highlight function.
##
## # Built-in Patterns
##   comment::
##     Comments start with # and are skipped during processing.
##   block_start::
##     A block keyword followed by arguments and { character.
##     Maps: keyword, indent, args, indent2, syntax3
##   block_end::
##     A closing } character. Maps: syntax
##   _unmatched::
##     Catch-all for lines that don't match any registered pattern.

NUDSL_CACHE_SUFFIX=".nux.dsl.sh"

## nux.dsl.eval:: <func> [<args>]
##   Evaluates a function call via the $nudsl_eval callable.
##   Provides a hook point so external code can replace eval with a
##   safer or debuggable execution mode.
##   Example: nudsl_eval=source  -- executes instead of eval
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

## nux.dsl.env::
##   Shell environment for a language definition. Sets up default .process
##   and .highlight callbacks that echo lines unchanged. Also provides
##   .highlight(type color) to set color variables, and .match(type regex ...)
##   to register a new parser pattern with variable assignments.

## nudsl_eval::
##   Global variable, default "eval". Can be overridden by calling
##   scripts to provide custom evaluation semantics.
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

## nux.dsl.process:: <action> <language_func> <file>
##   Runs a one-pass language compilation in a subshell. Loads the
##   language definition, then processes the file line-by-line.
##   The <action> parameter (plan or process) is passed through to
##   each matched line's callback function.
##   Returns the transformed output on stdout.

## nux.dsl.exec:: <language_func> <source_file> [<cached_file>]
##   Compiles a language file and loads it. The cached file defaults to
##   $source_file${NUDSL_CACHE_SUFFIX}. Skips compilation if the cached
##   file is newer than the source. Compilation failure removes the
##   cached output and returns an error.
##   The cached file is sourced after compilation, producing plain bash.
nux.dsl.exec() {
  local language="$1";
  local file="$2";
  local cached="${3:-$file${NUDSL_CACHE_SUFFIX}}";
  #FIXME: Add no-cache
  if nux.dsl.plan "$language" "$file" "$cached"; then
    source "$cached";
  fi
}

## nux.dsl.plan.file:: <language> <file>
##   Returns the cache file path for the given source file.
##   Appends .nux.dsl.sh suffix to the file path.
##   The language argument is not actually used in the computation.

nux.dsl.plan.file() {
  local language="$1"
  local file="$2";
  echo "$file${NUDSL_CACHE_SUFFIX}";
}

## nux.dsl.plan:: <language_func> <source_file> [<cached_file>]
##   Checks if compilation is needed by comparing file timestamps.
##   If recompilation is needed, runs nux.dsl.process in plan mode,
##   writes output to a temp file, then atomically moves it to the
##   cache location. Returns non-zero on compilation failure.
nux.dsl.plan() {
  local language="$1";
  local file="$2";
  local cached="${3:-$file${NUDSL_CACHE_SUFFIX}}";
  if [ "$file" -ot "$cached" ]; then
    nux.log debug "$file: No need to recompile."
    return;
  fi

  nux.log debug "$file: Needs recompilation - creating new version."

  local dirname=$(dirname "$cached")
  mkdir -p "$dirname";
  local execution_plan=$(mktemp -p "$dirname" .nux.dsl.XXXXXXXX)
  if (nux.dsl.process plan "$language" "$file" > "$execution_plan") ; then
    mv -f "$execution_plan" "$cached";
  else
    nux.log error "$file: Plan could not be generated. See errors."
    rm "$execution_plan"
    return -1;
  fi
}

## nux.dsl.process.fail:: <message>
##   Marks the current compilation as failed. Writes an error message
##   to stderr with the current line number prefix. Sets the
##   process_failed flag that causes the parser loop to abort.
##   Example: nux.dsl.process.fail "unmatched syntax at block start"
nux.dsl.process.fail() {
  process_failed=true
  echo "$linenum:$@" >&2
}

## nux.dsl.process0:: <action>
##   Core parser loop. Iterates over every line of a file, matching
##   each against registered regex patterns. On match, invokes the
##   corresponding `.gen.parser.<type>.process` function.
##   Stops and returns -1 if process_failed is set.
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
