.use-dsl nuxfs

dir.check.recover() {
  nuxfs.info "$rel_path" "Created directory";
  mkdir -p "$abs_path"
}
link.check.recover() {
  nuxfs.info "$rel_path" "Creating link to '$3'";
  ln -s "$target" "$abs_path"
}
git.check.recover() {
  $GIT_BIN clone "$origin" "$abs_path"
}
