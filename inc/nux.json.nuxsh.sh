## #nux.json NUX Script JSON Helper library
##
## #Public functions
@namespace nux.json. {
##   nux.json.start
##     Starts operation on new JSON. Resets write operations stack and JSON
##     source file to empty (useful for creating JSON from scratch.)

function :start {
  nux_json_opstack=".";
  nux_json_source="-n";
}

##   nux.json.open <file>
##     Opens JSON File for reading and writing using *nux.json.open* and
##     *nux.json.write* commands.
##
##     In order to work with empty JSON use *-n* as *file*. This allows
##     for creating new JSON from scratch.
##
##     NOTE: Open does not reset operation stack. To reset operation stack
##     and opened file use *nux.json.start*
function :open file {
  if [ -f "$file" ]; then
    nux_json_source="$file"
  fi
}

##   nux.json.read <path>
##     Reads *path* from currently opened JSON file.
##     NOTE: Read does not see changes performed by *nux.json.write* unless
##     these changes were flushed using *nux.json.flush*.
function :read path {
  jq -r ".$path" "$nux_json_source";
}

##   nux.json.write <path> <value>
##     Adds write operation to action stack. Writes are not performed
##     immediately, but rather when *nux.json.flush* is invoked.
##     This allows for batching of operations or opting out of actually
##     modifying file.
function :write path value {
  nux_json_opstack="${nux_json_opstack} | .$path |= \"$value\""
}

function :write.raw path value {
  nux_json_opstack="${nux_json_opstack} | .$path |= $value"
}

##   nux.json.flush [<target>]
##     Flushes any write operations to specified *target* file.
##     If *target* is not specified JSON is outputted to *STDIN*.
##
##     NOTE: Flush does not reset operation stack. To reset
##     operation stack and opened file use *nux.json.start*
##
function :flush target {
  if [ -n "$target" ]; then
    local write_target="$target";
    if [ "$nux_json_source" == "$target" ]; then
      write_target=$(mktemp "$(dirname "$target")/tempXXXXXX.json")
    fi
    jq -r "$nux_json_opstack" "$nux_json_source" > "$write_target"
    if [ "$nux_json_source" == "$target" ]; then
      mv -f "$write_target" "$target"
    fi
  else
    jq -r "$nux_json_opstack" "$nux_json_source"
  fi
}

##   nux.json.shorthands
##     Exposes shorthands for writing and reading from JSON file.
##        *njw* - nux.json.write
##        *njr* - nux.json.read
##
function :shorthands {
  function njw {
    nux.json.write "$@"
  }
  function njr {
    nux.json.read "$@"
  }
}

## # Usage Notes
##
## ## Operation stack and flush
##
## As mentioned in documentation for *nux.json.flush* write stack
## is not removed, but rather kept alone, separatly from reference
## to open file. This allows for having modification template
## which could be executed on multiple files.
##
## The following example adds meta.author and meta.email
## to every JSON in directory.
##
##   *nux.json.start*
##   *nux.json.write* meta.author "Tony Tkacik"
##   *nux.json.write* meta.email  "example@example.com"
##   *for* f *in* "*.json";
##   *do*
##      *nux.json.open* "$f"
##      *nux.json.flush* "$f"
##   *done*;
##
##

}
