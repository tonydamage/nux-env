

function exec.if.function {
	FUNC_NAME=$1;
	DEFAULT_NAME=$2;
	shift; shift;

	if nux.check.function $FUNC_NAME; then
		nux.log trace  Executing: $FUNC_NAME "$@";
		$FUNC_NAME "$@";
		return;
	fi
	if nux.check.function $DEFAULT_NAME; then
		nux.log trace  Executing: $FUNC_NAME "$@";
		$DEFAULT_NAME "$@";
		return;
	fi

}

function nuxfs.dsl.command {
	CMD=$1;
	localFile=$(nuxfs.relative "$2");


	shift; shift;
	nux.log trace  Processing $CMD "$localFile" $@;

	exec.if.function $CMD.pre def.pre "$localFile" "$@";

	if [[ "$NESTED_DIR" = "$localFile"* ||  "$localFile" = "$NESTED_DIR"*  ]]; then
		nux.log debug $localFile is affected by $NESTED_DIR;

  if [[ "$NESTED_DIR" = "$localFile/" || "$localFile" = "$NESTED_DIR"* ]]; then
		NUXFS_TARGET_FOUND=1;
	fi

	if nuxfs.file.exists "$localFile"; then
		nux.log debug  "File $NC_White$localFile$NC_No exits";
		exec.if.function $CMD.exists def.exists "$localFile" "$@";
	else
		nux.log debug  "File $NC_White$localFile$NC_No does not exists";
		exec.if.function $CMD.notexists def.notexists "$localFile" "$@";
  fi
	fi
	exec.if.function $CMD.post def.post "$localFile" "$@";
}


function nuxfs.dsl.keywords {
  origin() {
		:
	}
	name() {
		:
	}
	dir() {
		nuxfs.dsl.command directory "$@";
	}

	directory() {
		nuxfs.dsl.command directory "$@";
	}

	link() {
		nuxfs.dsl.command link "$@";
		#nux.log debug  ln -s "$ORIGIN/$1" "$VFS/$2" ;
	}

	git() {
		nuxfs.dsl.command git "$@";
		#echo git clone $1 $2;
	}

	directory.pre() {
		nuxfs.dir.push "$1"
		nux.log debug  "Adding to dir stack: $1"
	}

	directory.exists() {
		if test  -d "$1"; then
			nux.log debug  "Directory exists '$1'"
			nux.log trace  "Trying to nest into directory"
			if test -e "$1/.nuxfs"; then
				nux.log debug "Invoking nested nuxfs definition."
				source "$1/.nuxfs";
			fi;
		else
		  nuxfs.error "$1" "is not directory."
		fi
	}
	enddirectory() {
		nuxfs.dir.pop
	}
	enddir() {
		nuxfs.dir.pop
	}
}

function nuxfs.dsl.execute {
  nuxfs.dsl.keywords
	local DEF="$1";
	local DIR="$2";
	NESTED_DIR="$(realpath -s "$3")/";
	nux.log debug "Working Directory: $DIR , Nested Directory: $NESTED_DIR"
  declare -a DIR_ARRAY
  DIR_ARRAY[0]=$DIR
  if test -e "$DEF"; then
		NUXFS_TARGET_FOUND=0;
		source "$DEF";
		if [ $NUXFS_TARGET_FOUND = 0 ]; then
			nuxfs.warning "$3" "Does not have definition in $DEF";
		fi
	else
		nuxfs.error "$DEF"  Definition file does not exists.
	fi
}
