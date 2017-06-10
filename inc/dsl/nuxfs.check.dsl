.use-dsl nuxfs

link.entered() {
  nux.log debug  "Testing '$abs_path' as link"
  if test ! -h "$abs_path"; then
    nuxfs.error "$rel_path" "is not symlink."
    return
  fi
  local REAL_LINK=$(readlink "$abs_path")
  local TARGET="$3";
  nux.log trace "Target is: $TARGET, real link: $REAL_LINK"
  if test ! "$REAL_LINK" = "$TARGET"; then
    MAT_REAL=$(realpath "$REAL_LINK")
    local cdir=$(dirname "$abs_path")
    MAT_TARGET=$(realpath "$cdir/$TARGET")
    if test "$MAT_REAL" = "$MAT_TARGET"; then
      nuxfs.warning "$rel_path" "is using different definition for target '$3'"
    else
      nuxfs.error "$rel_path" "links to $REAL_LINK instead of $TARGET"
      return
    fi
  fi
  if test ! -e "$abs_path"; then
    nuxfs.warning "$rel_path" "target '$NC_White$TARGET$NC_No' does not exists."
  fi
}

git.entered() {
  nux.log debug "Testing '$rel_path' as git repository"
  if test ! -e "$rel_path/.git"; then
    nuxfs.error "$rel_path" "is not git repository"
    return
  fi
  local remotes=$(grep "$3" "$rel_path/.git/config" | wc -l)
  if [ $remotes -eq 0 ]; then
    nuxfs.error "$rel_path" "Does not refer git remote '$3'"
    return;
  fi
}
