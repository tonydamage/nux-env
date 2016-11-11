

function exec.if.function {
	FUNC_NAME=$1;
	DEFAULT_NAME=$2;
	shift; shift;

	if nux.check.function $FUNC_NAME; then
		nux.log debug  Executing: $FUNC_NAME "$@";
		$FUNC_NAME "$@";
		return;
	fi
	if nux.check.function $DEFAULT_NAME; then
		nux.log debug  Executing: $FUNC_NAME "$@";
		$DEFAULT_NAME "$@";
		return;
	fi

}

function nuxfs.dsl.command {
	CMD=$1;
	localFile=$(nuxfs.relative "$2");
	shift; shift;

	nux.log debug  Processing $CMD "$localFile" $@;

	exec.if.function $CMD.pre def.pre "$localFile" "$@";

	nux.log debug  Working file: $NC_White$localFile;
	if nuxfs.file.exists "$localFile"; then
		nux.log debug  "File $localFile exits";
		exec.if.function $CMD.exists def.exists "$localFile" "$@";
	else
		nux.log debug  "File $localFile does not exists";
		exec.if.function $CMD.notexists def.notexists "$localFile" "$@";
  fi
	exec.if.function $CMD.post def.post "$localFile" "$@";
}


function nuxfs.dsl.keywords {
  origin() {
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
  declare -a DIR_ARRAY
  DIR_ARRAY[0]=.
  if test -f "$1"; then
		source $1;
	else
		error "$1": Definition file does not exists.
	fi
}
