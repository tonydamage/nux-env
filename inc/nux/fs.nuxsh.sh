nux.use nux/check
@prefix check nux.check.

@namespace nux.fs. {

  function :exists target {
      check:file.exists "$target";
  }

  function :closest target {
    cdir="${2:-$(pwd)}";
  	nux.log trace "Searching in: " $cdir;
  	until [ -e "$cdir/$target" -o "$cdir" == "/" ]; do
  		 cdir=$(dirname "$cdir");
  		 nux.log trace "Searching in: " $cdir;
	  done;
	 if [ -e "$cdir/$target" ]; then
  		 echo "$cdir/$target";
	 fi
  }

  function :path.relative.pwd target {
    realpath -Lms --relative-to="$(pwd)" "$target"
  }

  function :path.relative base target {
    realpath -Lms --relative-to="$base" "$target"
  }

  function :path.display target {
    echo $NC_LightPurple$(nux.fs.path.relative.pwd "$target")$NC_No;
  }

  function :symlink target dir name {
    relative=$(nux.fs.path.relative "$dir" "$target")
    nux.log debug "Relative path is: $relative"
    :stage mkdir -p "$dir"
    if [ -n "$name" ]; then
      :stage ln -sf "$relative" "$dir/$name"
    else
      :stage ln -sf "$relative" "$dir"
    fi
  }

  function :stage {
    if [ -n "$NUXFS_STAGE" ]; then
      echo "[stage]" "$@"
    else
      "$@"
    fi
  }

  function :error file {
  	local filename=$(nux.fs.path.relative.pwd "$file");
  	nux.echo.error "$filename$NC_No: $@$NC_No";
  }

  function :warning file {
  	local filename=$(nux.fs.path.relative.pwd "$file");
  	nux.echo.warning "$filename$NC_No: $@$NC_No";
  }

  function :info file {
  	local filename=$(nux.fs.path.relative.pwd "$file");
  	echo -e "$NC_White$filename$NC_No: $@$NC_No";
  }
}
