.use-dsl nuxfs

.entered() {
  nux.dsl.info "$rel_path" $keyword
}

.check() {
  return 0;
}
