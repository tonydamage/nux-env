nux.use nux.mime

@namespace thumby {
  function :name.shared {
    echo $(basename "$1"|md5sum|cut -d " " -f1).png
  }

  function :noop {
    :
  }

  function :image.size {
    raw_str=$(identify "$1")
    str=${raw_str#$1 * }
    echo ${str%% *}
  }

  function :mimetype.supported {
    local mimetype="$1";
    local base="${mimetype%%/*}";
    local helper="${mimetype/\//.}";
    if [ "$base" == "image" ]; then
        return 0;
    elif nux.check.function thumby.thumb.source.locator.$helper; then
        return 0;
    elif nux.check.function thumby.thumb.source.extractor.$helper; then
        return 0;
    fi
    return 1;
  }
}

@namespace thumby.thumb {

  function :should.generate path mimetype {
    local thumbpath=$(thumby.thumb.path "$path");
    local source=$(thumby.thumb.source "$path" "$mimetype");
    if [ "$source" -nt "$thumbpath" ]; then
      return 0;
    else
      return 1;
    fi
  }

  function :can.generate path mimetype {
    local helper="${mimetype/\//.}";

    if ! thumby.mimetype.supported "$mimetype" {
      return 1;
    }

    if nux.check.function thumby.thumb.source.locator.$helper {
      local source=$(thumby.thumb.source.locator.$helper "$path");
      if [ -z "$source" ] {
        return 1;
      }
    }
    return 0;
  }

  function :source path mimetype {
    local helper="${mimetype/\//.}";
    if nux.check.function thumby.thumb.source.locator.$helper; then
      thumby.thumb.source.locator.$helper "$path"
    else
        echo "$path";
    fi
  }

  function :path path {
    local filename=$(basename "$path")
    local dirname=$(dirname "$path")
    local thumbname="$(thumby.name.shared "$filename")";
    echo "$dirname/.sh_thumbnails/large/$thumbname";
  }

  function :get path mimetype {

    nux.log debug "thumby path: $path";
    if [ ! -e "$path" ] ; then
      return -1;
    fi

    if [ -z "$mimetype" ] ; then
      mimetype=$(nux.mime "$path")
    fi

    local filename=$(basename "$path")
    local dirname=$(dirname "$path")
    local thumbname="$(thumby.name.shared "$filename")";
    local thumbpath="$dirname/.sh_thumbnails/large/$thumbname";

    nux.log debug "Dir: $dirname, File: $filename, thumb: $thumbname"

    if thumby.thumb.should.generate "$path" "$mimetype" {

      helper="${mimetype/\//.}"
      nux.log debug "File $path, type $mimetype does not have thumbnail. Trying to generate using $helper."

      local preexec=thumby.noop;
      local postexec=thumby.noop;
      local source=$path;
      local streamer=thumby.noop;
      if nux.check.function thumby.thumb.source.locator.$helper ; then
        source=$(thumby.thumb.source.locator.$helper "$path");
      fi
      if nux.check.function thumby.thumb.source.extractor.$helper ; then
        echo "Using source helper" >&2
        source="-"
        streamer=thumby.thumb.source.extractor.$helper;
      fi
      nux.log debug "File $path, using '$source' as source. Using stremer '$streamer'"
      mkdir -p "$dirname/.sh_thumbnails/large" &>/dev/null
      mtime=`stat -c '%Y' "$path"`

      $preexec "$path"
      nux.log info "Source is : $source, Streamer is $streamer";
      $streamer "$path" | convert -thumbnail '256x256>' -strip "$source" "$thumbpath" >&2
      $postexec "$path"
    }
    if [ -e "$thumbpath" ]; then
      echo $thumbpath;
    fi
  }

  function :generate {
    convert -thumbnail '256x256>' -strip "$path" "$thumbpath" >&2
  }

}
