.use-dsl nuxfs.apply

should-not-exists.check.failed() {
for f in "$rel_path"; do
  rm -r "$f"
  nux.dsl.info $f Deleted.
done
}

cathegorize.process.file() {
  mv "$rel_file" "$cat_dir"
  nux.dsl.info "$rel_file" Moved to $NC_White$cat_dir$NC_No
}
