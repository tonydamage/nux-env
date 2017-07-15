nux.mime() {
  local type=binary/octet
  local suffix="${1##*.}"
  case "${suffix,,}" in
    txt) type=text/plain;;
    css) type=text/css;;
    jpg) type=image/jpeg;;
    png) type=image/png;;
    zip) type=application/zip;;
    cbr) type=application/x-cbz;;
    cbz) type=application/x-cbr;;
    pdf) type=application/pdf;;
    epub) type=application/epub+zip;;
    mp4) type=video/mp4;;
    *)
    if [ -d "$1" ]; then
      type=directory
    fi
  esac
  echo $type;

}
