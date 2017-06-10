function nux.dsl.block.type {
  echo ${DSL_BLOCK_TYPE[${#DSL_BLOCK_TYPE[@]}-1]}
}

function nux.dsl.block.id {
	echo ${DSL_BLOCK_ID[${#DSL_BLOCK_ID[@]}-1]}
}

function nux.dsl.block.path {
	echo ${DSL_BLOCK_PATH[${#DSL_BLOCK_PATH[@]}-1]}
}

function nux.dsl.block.pop {
  unset DSL_BLOCK_TYPE[${#DSL_BLOCK_TYPE[@]}-1]
	unset DSL_BLOCK_ID[${#DSL_BLOCK_ID[@]}-1]
  unset DSL_BLOCK_PATH[${#DSL_BLOCK_PATH[@]}-1]
}

function nux.dsl.block.init {
  DSL_BLOCK_TYPE[${#DSL_BLOCK_TYPE[@]}]="root"
  DSL_BLOCK_ID[${#DSL_BLOCK_ID[@]}]="."
  DSL_BLOCK_PATH[${#DSL_BLOCK_PATH[@]}]=".";
}

function nux.dsl.block.push {
  local btype="$1"
  local value="$2"
  local parent=$(nux.dsl.block.path)
  #nux.log trace "Pushing $NC_White$btype '$value'$NC_No on stack."
  DSL_BLOCK_TYPE[${#DSL_BLOCK_TYPE[@]}]="$btype"
  DSL_BLOCK_ID[${#DSL_BLOCK_ID[@]}]="$value"
  DSL_BLOCK_PATH[${#DSL_BLOCK_PATH[@]}]="$parent/$value";
}

function nux.dsl.error {
  local tag="$1"; shift;
	nux.echo.error "$tag"$NC_No: $*;
}

function nux.dsl.warning {
  local tag="$1"; shift;
	nux.echo.warning "$tag"$NC_No: $*;
}

function nux.dsl.info {
  local tag="$1"; shift;
	echo -e $NC_White"$tag"$NC_No:  $*;
}

function nux.dsl.keyword.exec {
  local func="$1";
  local keyword="$2";
  local FUNC_NAME=$keyword$func;
	local DEFAULT_NAME=$func;
  local ALLWAYS_NAME=.allways$func;

	shift; shift;
  if nux.check.function $ALLWAYS_NAME; then
		nux.log trace  Executing: $NC_White$ALLWAYS_NAME$NC_No "$@";
		$ALLWAYS_NAME "$@";
  fi
  if nux.check.function $FUNC_NAME; then
		nux.log trace  Executing: $NC_White$FUNC_NAME$NC_No "$@";
		$FUNC_NAME "$@";
		return $?;
	elif nux.check.function $DEFAULT_NAME; then
		nux.log trace  Executing: $NC_White$DEFAULT_NAME$NC_No "$@";
		$DEFAULT_NAME "$@";
		return $?;
	fi
}

function nux.dsl.only.subtree {
  nux.log debug "Subtree to process: $NC_White$1$NC_No"
  nux_dsl_only_subtree="$1";
}

function nux.dsl.block.start {
  parent=$(nux.dsl.block.path);
  keyword="$1";
  id="$2";
  path="$parent/$id";

  nux.log trace Starting Block: "$keyword" ID: "$id" Parent: $parent
  #nux.log debug "Skip is: $nux_dsl_skip, test should return $(test -z "$nux_dsl_skip")"
  nux.dsl.block.push "$keyword" "$id"
  if [[ $path == $nux_dsl_only_subtree* && -z "$nux_dsl_skip" ]]; then
    nux.dsl.keyword.exec .preprocess "$keyword" "$@";
    if nux.dsl.keyword.exec .check "$keyword" "$@"; then
        nux.dsl.keyword.exec .entered "$keyword" "$@"
    else
      if nux.dsl.keyword.exec .check.recover "$1" "$@"; then
          nux.log trace "Successfully recovered for $keyword $id"
      else
          nux.dsl.keyword.exec .check.failed "$1" "$@";
          nux.log trace Skipping children of $NC_White$path$NC_No
          nux_dsl_skip="$path"
      fi
    fi
  fi

}

function nux.dsl.block.end {
  keyword=$(nux.dsl.block.type)
  id=$(nux.dsl.block.id)
  path=$(nux.dsl.block.path)

  #nux.log trace Ending block $NC_White"$keyword" "'$id'"
  nux.dsl.block.pop "$1"

  if [ "$path" = "$nux_dsl_skip" ];then
    nux_dsl_skip="";
  fi
  if [[ $path == $nux_dsl_only_subtree* ]]; then
    nux.dsl.keyword.exec .exited "$keyword" "'$id'"
  fi
}

function nux.dsl.execute {
  local language=$1
  local script=$2
  local language_dir=$(dirname "$language");
  local script_dir=$(dirname "$script");
  function .use-dsl {
    if nux.check.file.exists "$language_dir/$1.dsl"; then
      source "$language_dir/$1.dsl";
    elif nux.check.file.exists "$script_dir/$1.dsl"; then
      source "$script_dir/$1.dsl";
    else
      nux.dsl.error $1 Language not found in $NC_White$language_dir$NC_No and $NC_White$script_dir$NC_No
      exit 1;
    fi
  }

  function .entered {
    nux.log debug Keyword $NC_White$1$NC_No is noop.
  }
  function .block.entered {
    nux.log debug Keyword $NC_White$1$NC_No is noop.
  }

  function .check.recover {
    return 1
  }

  function .arg.parser {
    keyword="$1"; shift;
    offset=1;
    echo """# Parsing arguments

        keyword=$keyword
        id=\"\$1\""""
    for var in "$@"; do
      echo "        ${var}=\"\$$offset\""
      let offset=$offset+1
    done
  }


  function .block {
    local keyword="$1"
    nux.log trace Defining block keyword $NC_White"$keyword"
    #FIXME: Add aliasing of binary of same name.
    nux.eval """
      $keyword() {
        $(.arg.parser "$@")
        nux.dsl.block.start $keyword \"\$@\";
      }
      end$keyword() {
        nux.dsl.block.end $keyword
      }
    """
  }

  function .keyword {
    local keyword="$1"
    #FIXME: Add aliasing of binary of same name.
    nux.log trace Defining keyword $NC_White"$keyword"
    nux.eval """
      $keyword() {
        $(.arg.parser "$@")
        nux.dsl.block.start $keyword \"\$@\";
        nux.dsl.block.end $keyword;
      }
    """
  }

  .keyword.virtual() {
    local keyword=$1
    .keyword "$@"
    nux.eval """
      ${keyword}.check() {
        return 0;
    }
    """
  }

  .block.virtual() {
    local keyword=$1
    .block "$@"
    nux.eval """
      ${keyword}.check() {
        return 0;
    }
    """
  }

  nux.dsl.block.init
  source "$language.dsl"
  source "$script"
}
