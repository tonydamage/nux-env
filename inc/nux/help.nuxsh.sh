#!/usr/bin/env nuxsh
@namespace nux.help. {
  function :shelldoc {
    sed -r \
      -e "s/^## ?(.*)/${NC_White}\1${NC_No}/gI" \
      -e "s/^# ?(.*)/${NC_Bold}\1${NC_No}/gI" \
      -e "s/^([ a-z0-9.-_]*)::/${NC_Bold}\1${NC_No}/gI" \
      -e "s/\*\*([^*]*)\*\*/${NC_Bold}\1${NC_No}/gI"  \
      -e "s/\*([^*]*)\*/${NC_White}\1${NC_No}/gI"  \
      --
  }

  function :comment source {
    if nux.check.file.exists "$source" ; then
      grep -E "^\#\#( |$)" "$source" \
        | cut -d\# -f3- \
        | cut -d" " -f2- \
        | nux.help.shelldoc
    fi
  }
}
