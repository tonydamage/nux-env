function nux.mime {
    nux.mime.naive.suffix "$@"
}

@namespace nux.mime {

  function :naive.suffix filename {
    local type=binary/octet
    local suffix="${filename##*.}"
    suffix="${suffix,,}"
    if [ -d "$filename" ]; then
      type=directory
    else
      case "${suffix,,}" in

        txt) type=text/plain;;
        css) type=text/css;;

        jpeg) ;&
        jpg) type=image/jpeg;;

        png) type=image/png;;
        zip) type=application/zip;;

        cbr) type=application/x-cbz;;
        cbz) type=application/x-cbr;;

        pdf) type=application/pdf;;
        epub) type=application/epub+zip;;
        mp4) type=video/mp4;;
      esac
    fi
    echo $type;

  }

}
