#/bin/sh

.block dir name
.keyword link name target
.keyword git name origin
.keyword origin
.keyword name name
.keyword template
.keyword exists
.keyword should-not-exists

directory() {
  dir
}

sdir() {
  dir "$@"
  enddir
}

.allways.preprocess() {
  abs_path=$(realpath -Lms "$NUXFS_DEF_DIR/$path");
  rel_path=$(realpath -Lms "$abs_path" --relative-base="$WORKDIR");
  def_path=$(realpath -Lms "$path" --relative-to="$NUXFS_DEF_DIR")
}

.check() {
  nux.log trace "Checking existence of $NC_White$abs_path$NC_No"
  nux.check.file.exists "$abs_path"
}

.check.failed() {
  if [ -z "$NUXFS_IGNORE_MISSING" ]; then
    nux.dsl.error "$rel_path" does not exists.
  fi
}
dir.entered() {
  if nux.check.file.exists "$abs_path/.nuxfs"; then
    source "$abs_path/.nuxfs"
  fi
}

should-not-exists.check() {
  nux.log trace "Checking existence of $NC_White$abs_path$NC_No"
  if nux.check.file.exists "$abs_path"; then
    return 1
  fi
  return 0
}

should-not-exists.check.failed() {
  for f in "$rel_path"; do
    nux.dsl.error $f Should not exists, but is present.
  done
}
