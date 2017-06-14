#/bin/sh

## # NUXFS Domain Specific Language
##
## *nuxfs* command has its own DSL to describe rules and structure of filesystem
## and content of files. It uses file structure definition present in *.nuxfs*
## file to understand intented state of directory / filesystem of user.
##
## This definition is not only used to create filesystem hierarchy, checkout git
## repositories but also to verify state of filesystem afterwards.
##
## ## Example of .nuxfs file in home directory
##
##   *dir* github
##     *git* nux-env https://github.com/tonydamage/nux-env.git
##     *git* bats https://github.com/sstephenson/bats.git
##   *enddir*
##   *link* .bashrc github/nux-env/bashrc
##
## This *.nuxfs* file describes simple home structure. When *nuxfs apply*
## is executed in folder containing this file, it is equivalent of executing
## following commands:
##
##    mkdir -p github
##    git clone https://github.com/tonydamage/nux-env.git github/nux-env
##    git clone https://github.com/sstephenson/bats.git
##    ln -s github/nux-env/bashrc .bashrc
##
## If we manually remove *github/bats* directory and run *nuxfs check* afterwards
## the *github/bats* directory will be reported as missing.
##
## If we execute *nuxfs apply*, only missing *github/bats* will be cloned.
##
## # Available Keywords

##   dir <name>
##        Block keyword which defines directory with specified *name*.
##        All subsequent keywords represent nested items in these directory
##        unless **enddir** keyword is encountered.
##
.block dir name

##   link <name> <target>
##        Defines a symbolik link with specified *name*, which points to
##        specified target
##
.keyword link name target

##   git <name> <origin>
##      Defines an existence of folder with specified *name*, which
##      is git repository clone of specified *origin*
##
.keyword git name origin

.keyword origin
.keyword name name
.keyword template

##   exists <name>
##        Defines an existence of file with specified *name*.
##        When *nuxfs check* is executed absence of this file would result
##        into error report.
##
.keyword exists name

##
.keyword should-not-exists

.keyword cathegorize match min delimiter
cathegorize.check() {
  test $(find "$(dirname "$abs_path")" -maxdepth 1 -iname "$match" | wc -l) -gt 0
}

cathegorize.cathegory() {
  sed -r -e "s/$delimiter/:/g" | cut -d: -f1
}
cathegorize.entered() {
  local parent_dir=$(dirname "$rel_path");
  local cathegories=$((cd "$parent_dir"; find -maxdepth 1 -iname "$match") \
    | cut -d"/" -f2 \
    | cathegorize.cathegory | sort | uniq -c \
    | while IFS=" " read count cathegory
        do
          if [ $count -ge $min ]; then
            echo $theme $cathegory
          fi
        done
    )

  for cat in $cathegories; do
    cat_dir=$parent_dir/$cat;
    if [ ! -d "$cat_dir" ]; then
      cathegorize.process.dir "$@"
    fi
  done

  (cd "$parent_dir"; find -maxdepth 1 -iname "$match") \
    | while read file
        do
          file=$(basename "$file")
          cathegory=$(echo $file | cathegorize.cathegory)

          if [[ $cathegories =~ "$cathegory" ]];then
            rel_file=$parent_dir/$file
            cat_dir=$parent_dir/$cathegory
            cathegorize.process.file "$@"
          fi
        done

}

cathegorize.process.dir() {
  nux.dsl.error "$cat_dir" Does not exits. Required by cathegorize
}

cathegorize.process.file() {
  nux.dsl.error "$rel_file" Should be in $NC_White$cat_dir$NC_No
}

cathegorize.check.failed() {
  nux.log debug Noop, no files to cathegorize
}

directory() {
  dir
}

sdir() {
  dir "$@"
  enddir
}
##
## #Using custom keywords
##
## *nuxfs* allows for addition of custom directory specific keywords,
## since it is based on *nuxdsl* library.
##
## FIXME: Describe how to add keywords
##
.info() {
  nux.dsl.info "$rel_path" "$@"
}

.warning() {
  nux.dsl.warning "$rel_path" "$@"
}

.error() {
  nux.dsl.error "$rel_path" "$@"
}

.should.eq() {
  local actual="$1"
  local expected="$2"
  shift;shift;
  if [ "$actual" != "$expected" ]; then
    .warning "$@"
  fi
}

.must.eq() {
  local actual="$1"
  local expected="$2"
  shift;shift;
  if [ "$actual" != "$expected" ]; then
    .error "$@"
  fi
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
    .error does not exists.
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
