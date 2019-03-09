
@namespace thumby.thumb.source {

  function :locator.directory {
    if [ -e "$1/.thumb.jpg" ]; then
      echo "$1/.thumb.jpg";
    elif [ -e "$1/.thumb.png" ]; then
      echo "$1/.thumb.png";
    #  find -L "$1" -maxdepth 1 -iname "*.jpg" -or -iname "*.png" | sort -n | head -n1
    fi
  }

  function :locator.application.pdf {
    echo "$1[0]"
  }

  function :extractor.application.epub+zip() {

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

  function :extractor.application.x-cbr() {
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

}
