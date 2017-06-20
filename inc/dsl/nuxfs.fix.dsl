.use-dsl nuxfs.apply

should-not-exists.check.failed() {
  find "$(dirname "$rel_path")" -maxdepth 1 -iname "$id" -delete
}

cathegorize.process.file() {
  mv "$rel_file" "$cat_dir"
  nux.dsl.info "$rel_file" Moved to $NC_White$cat_dir$NC_No
}
