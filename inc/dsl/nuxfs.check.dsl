.use-dsl nuxfs

link.entered() {
  nux.log debug  "Testing '$abs_path' as link"
  if test ! -h "$abs_path"; then
    .error "is not symlink."
    return
  fi
  local REAL_LINK=$(readlink "$abs_path")
  nux.log trace "Target is: $target, real link: $REAL_LINK"
  if test ! "$REAL_LINK" = "$target"; then
    MAT_REAL=$(realpath "$REAL_LINK")
    local cdir=$(dirname "$abs_path")
    MAT_TARGET=$(realpath "$cdir/$target")
    if test "$MAT_REAL" = "$MAT_TARGET"; then
      .warning "is using different definition for target '$3'"
    else
      .error "links to $REAL_LINK instead of $target"
      return
    fi
  fi
  if test ! -e "$abs_path"; then
    .warning "target '$NC_White$target$NC_No' does not exists."
  fi
}

git.entered() {
  nux.log debug "Testing '$rel_path' as git repository"
  if test ! -e "$rel_path/.git"; then
    .error "$rel_path" "is not git repository"
    return
  fi
  local remotes=$(grep "$origin" "$rel_path/.git/config" | wc -l)
  if [ $remotes -eq 0 ]; then
    .error "$rel_path" "Does not refer git remote '$origin'"
    return;
  fi
}

cathegorize.cathegories() {
  nux.dsl.error Proposed cathegories: $NC_White$cathegories$NC_No
  for cat in $cathegories; do
    cat_dir=$parent_dir/$cat;
    if [ ! -d "$cat_dir" ]; then
      nux.dsl.error $cat_dir Does not exits. Required by $NC_White$@$NC_No
    fi
  done
}

cathegorize.files() {
  (cd "$parent_dir"; find -maxdepth 1 -iname "$match") \
    | while read file
        do
          file=$(basename "$file")
          cathegory=$(echo $file | cathegorize.cathegory)
          if [[ $cathegories =~ "$cathegory" ]];then
            nux.dsl.error "$parent_dir/$file" Should be in $cathegory
          fi
        done
}
