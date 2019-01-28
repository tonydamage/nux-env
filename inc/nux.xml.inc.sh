## #nux.json NUX Script JSON Helper library
##
## #Public functions

##   nux.xml.start
##     Starts operation on new JSON. Resets write operations stack and JSON
##     source file to empty (useful for creating JSON from scratch.)
function nux.xml.start {
  nux_xml_opstack="";
  nux_xml_source="";
  nux_xml_root="";
}

##   nux.xml.open <file>
##     Opens JSON File for reading and writing using *nux.xml.open* and
##     *nux.xml.write* commands.
##
##     In order to work with empty JSON use *-n* as *file*. This allows
##     for creating new JSON from scratch.
##
##     NOTE: Open does not reset operation stack. To reset operation stack
##     and opened file use *nux.xml.start*
function nux.xml.open {
  local file="$1"
  if [ -f "$file" ]; then
    nux_xml_source="$file"
  fi
}

##   nux.xml.read <path>
##     Reads *path* from currently opened JSON file.
##     NOTE: Read does not see changes performed by *nux.xml.write* unless
##     these changes were flushed using *nux.xml.flush*.
function nux.xml.read {
  local path=".$1";
  xmlstarlet -r "$path" "$nux_xml_source";
}

##   nux.xml.write <path> <value>
##     Adds write operation to action stack. Writes are not performed
##     immediately, but rather when *nux.xml.flush* is invoked.
##     This allows for batching of operations or opting out of actually
##     modifying file.
function nux.xml.write {
  local path="/${1//\./\/}";
  if [ -z "$nux_xml_root" ] ; then
    nux_xml_root=$(cut -d "/" -f2 <<< "$path")
    nux.log debug "Root is $nux_xml_root";
  fi
  nux.log debug "Path to write is: $path";
  local value="$2";
  nux_xml_opstack="${nux_xml_opstack} -a $path -t elem -v \"$value\""
}

function nux.xml.write.raw {
  local path=".$1";
  local value="$2";
  nux_xml_opstack="${nux_xml_opstack} | $path |= $value"
}

##   nux.xml.flush [<target>]
##     Flushes any write operations to specified *target* file.
##     If *target* is not specified JSON is outputted to *STDIN*.
##
##     NOTE: Flush does not reset operation stack. To reset
##     operation stack and opened file use *nux.xml.start*
##
function nux.xml.flush {
  local target="$1"
  if [ -z "$nux_xml_source" ] ; then
    nux_xml_source=$(mktemp);
    echo "<$nux_xml_root></$nux_xml_root>";
  fi
  nux.log debug Opstack is: $nux_xml_opstack
  if [ -n "$target" ]; then
    local write_target="$target";
    if [ "$nux_xml_source" == "$target" ]; then
      write_target=$(mktemp "$(dirname "$target")/tempXXXXXX.json")
    fi
    xmlstarlet ed $nux_xml_opstack "$nux_xml_source" > "$write_target"
    if [ "$nux_xml_source" == "$target" ]; then
      mv -f "$write_target" "$target"
    fi
  else
    xmlstarlet ed $nux_xml_opstack "$nux_xml_source"
  fi
}

##   nux.xml.shorthands
##     Exposes shorthands for writing and reading from JSON file.
##        *njw* - nux.xml.write
##        *njr* - nux.xml.read
##
function nux.xml.shorthands {
  function nxw {
    nux.xml.write "$@"
  }
  function nxr {
    nux.xml.read "$@"
  }
}

## # Usage Notes
##
## ## Operation stack and flush
##
## As mentioned in documentation for *nux.xml.flush* write stack
## is not removed, but rather kept alone, separatly from reference
## to open file. This allows for having modification template
## which could be executed on multiple files.
##
## The following example adds meta.author and meta.email
## to every JSON in directory.
##
##   *nux.xml.start*
##   *nux.xml.write* meta.author "Tony Tkacik"
##   *nux.xml.write* meta.email  "example@example.com"
##   *for* f *in* "*.xml";
##   *do*
##      *nux.xml.open* "$f"
##      *nux.xml.flush* "$f"
##   *done*;
##
##
