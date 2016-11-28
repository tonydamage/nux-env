function nuxfs.relative {
	echo "$(nuxfs.dir.get)/$1"
}

function nuxfs.error {
	local filename=$1; shift;
	nux.echo.error "$filename"$NC_No:  $*;
}

function nuxfs.warning {
	local filename=$1; shift;
	nux.echo.warning "$filename"$NC_No: $*;
}

function nuxfs.info {
	local filename=$1; shift;
	echo -e $NC_White"$filename"$NC_No:  $*;
}

function nuxfs.dir.get {
	echo ${DIR_ARRAY[${#DIR_ARRAY[@]}-1]}
}

function nuxfs.dir.pop {
	unset DIR_ARRAY[${#DIR_ARRAY[@]}-1]
}

function nuxfs.dir.push {
	local value="$1"
  DIR_ARRAY[${#DIR_ARRAY[@]}]="$value"
}

function nuxfs.file.exists {
	test -e "$1" -o -h "$1";
}

function nuxfs.closest {
  cmd=$1;
  cdir=$(pwd);
	nux.log trace "Searching in: " $cdir;
	until [ -e "$cdir/$1" -o "$cdir" == "/" ]; do
		 cdir=$(dirname "$cdir");
		 nux.log trace "Searching in: " $cdir;
	 done;
	 if [ -e "$cdir/$1" ]; then
		 echo "$cdir/$1";
	 fi
}
