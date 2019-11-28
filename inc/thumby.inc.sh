nux.use nux.mime

type gm /dev/null 2>&1 && NUX_MAGICK=gm

function thumby.name.shared() {
  echo $(basename "$1"|md5sum|cut -d " " -f1).png
}

function thumby.noop() {
  :
}

function thumby.mimetype.supported() {
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


function thumby.thumb.can.generate() {
  local path="$1";
  local mimetype="$2";
  local helper="${mimetype/\//.}";

  if ! thumby.mimetype.supported "$mimetype" ; then
    return 1;
  fi

  if nux.check.function thumby.thumb.source.locator.$helper; then
    local source=$(thumby.thumb.source.locator.$helper "$path");
    if [ -z "$source" ] ; then
      return 1;
    fi
  fi
  return 0;
}

function thumby.thumb.get() {
  local path="$1";
  local mimetype="$2";

  if [ ! -e "$path" ] ; then
    return -1;
  fi

  if [ -z "$mimetype" ] ; then
    mimetype=$(nux.mime "$path")
  fi

  local filename=$(basename "$1")
  local dirname=$(dirname "$1")
  local thumbname="$(thumby.name.shared "$filename")";
  local thumbpath="$dirname/.sh_thumbnails/large/$thumbname";
  if [ ! -e "$thumbpath" ]; then

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


    mkdir -p "$dirname/.sh_thumbnails/large" &>/dev/null
    mtime=`stat -c '%Y' "$path"`

    $preexec "$path"
    nux.log info "Source is : $source, Streamer is $streamer";
    $streamer "$path" | $NUX_MAGICK  convert -thumbnail '256x256>' -strip "$source" "$thumbpath" >&2
    $postexec "$path"
    echo $thumbpath;
  fi

}

function thumby.thumb.generate() {
  $NUX_MAGICK convert -thumbnail '256x256>' -strip "$path" "$thumbpath" >&2
}

function thumby.get.thumb() {
  local path="$1";
  local d="$(dirname "$1")";
  local f=$(basename "$1");
  local thumb_name="$(thumby.name.shared "$f")"
  if [ ! -e "$path" ] ; then
  return;
  elif [ ! -e "$d/.sh_thumbnails/large/$thumb_name" ] ; then
    #mkdir -p .sh_thumbnails/normal &>/dev/null
    mkdir -p "$d/.sh_thumbnails/large" &>/dev/null
    #md5=`echo $path|md5sum|cut -d" " -f1`
    mtime=`stat -c '%Y' "$path"`
    nux.log info "Generating thumbnails for $path $thumb_name" >&2
    #convert -thumbnail '128x128>' -strip -set Thumb::MTime "$mtime" -set Thumb::URI "$path" "$path" .sh_thumbnails/normal/$md5.$THUMB_TYPE >&2
    nux.log info "Command line is: " # echo convert -thumbnail '256x256>' -strip -set Thumb::MTime "$mtime" -set Thumb::URI "$path" "$path" .sh_thumbnails/large/$thumb_name
    nux.log info convert -thumbnail '256x256>' --strip "$path" "$d"/.sh_thumbnails/large/$thumb_name
    convert -thumbnail '256x256>' -strip "$path" "$d"/.sh_thumbnails/large/$thumb_name >&2
  fi
  echo "$d/.sh_thumbnails/large/$thumb_name"
}


thumby.thumb.source.locator.directory() {
  nux.log info "Using find to find jpg or png"
  find "$1" -maxdepth 1 -iname "*.jpg" -or -iname "*.png" | sort -n | head -n1
}

thumby.thumb.source.locator.application.pdf() {
  echo "$1[0]"
}

thumby.thumb.source.extractor.application.epub+zip() {

  local rootDesc=$(unzip -p "$1" META-INF/container.xml \
    | xmlstarlet sel -N od="urn:oasis:names:tc:opendocument:xmlns:container" \
       -t -v "/od:container/od:rootfiles/od:rootfile[@media-type='application/oebps-package+xml']/@full-path" -n)
  nux.log info "Root description is in: $rootDesc";
  local imgDesc=$(unzip -p "$1" "$rootDesc" \
    | xmlstarlet sel -N opf="http://www.idpf.org/2007/opf"  \
        -t -m "/opf:package/opf:manifest/opf:item[@id=/opf:package/opf:metadata/opf:meta[@name='cover']/@content]" \
        -v "@href" -o ":" -v "@media-type" -n)
  IFS=":" read -r img media <<< "$imgDesc";
  nux.log info "Image name is $imgDesc $img";
  if [ -n "$img" ]; then
    unzip -p "$1" $img
  fi
}

thumby.thumb.source.extractor.application.x-cbr() {
  suffix="${1##*.}"
  case "$suffix" in
    zip) ;&
    cbz)
      potential=$(unzip -l "$1" | sed -re "s/^ *[0-9]+ +[0-9\\-]+ +[0-9:]+ +//gi" | grep -E '\.((jpg)|(png)|(jpeg))$' | sort -n | head -n 1)
      nux.log debug "Potential preview is: $potential";
      if [ -n "$potential" ]; then
        unzip -p "$1" "$potential"
        nux.log debug "Preview extracted."
      fi
    ;;
    *) nux.log error "$suffix is not supported."
  esac
}
