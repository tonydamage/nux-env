nux_meta_backends="func file"

@namespace nux.meta {

  function :add-impl impl {
    nux_meta_backends="$impl $nux_meta_backends"
  }

  function :get filename name default {
    for backend in $nux_meta_backends; do
      #nux.log debug "Invoking $backend nux.meta.impl.$backend.get $(declare -f nux.meta.impl.$backend.get)";
      local value=$(nux.meta.impl.$backend.get "$filename" "$name");
      if [ -n "$value" ] {
        echo "$value"
        return 0;
      }
    done
    if [ -z "$default" ] {
      return 1;
    }
    echo "$default"
  }
}

@namespace nux.meta.impl.file {

  function :get filename name {
    if [ -e "$filename/.nux.meta" ] {
        grep "^$name " "$filename/.nux.meta" | cut -d " " -f2-
    }
  }

  function :add filename name value {
    local meta="$filename/.nux.meta";
    local metaline="$name $value";

    if ! ( [ -e "$meta" ] &&  grep "^$metaline\$" "$meta" > /dev/null ) {
      nux.log debug "Writing pin to $meta"
      echo "$metaline" >> "$meta"
    }
  }

}

@namespace nux.meta.impl.func {
  function :get filename name {
    local funcspec="${name//:/.}"
    nux.exec.optional "nux.meta.impl.func.$funcspec" "$filename"
  }
}
