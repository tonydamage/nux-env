## #nuweb - Server-side HTTP scripting library for BASH
##
## *nuweb* is set of BASH function to ease implementation of CGI scripts using
## BASH. Idea behind it, is to allow for reuse of existing shell scripts
## and command-line utilities, without need to duplicate functionality.
##
## *nuweb* is based on *nux-env*, which allows large code-share with *nux-env*
## command line tools and use of *nux-env* libraries.
##
## *nuweb* is separated into several components:
##
##    nuweb::
##        this library, base functionality
##    nuweb/router:: router support functionality - dispatch of code
##      based on path and query parameters
##    nuweb/html::
##      basic support for generating HTML content
##

## #Public functions:

## nuweb.status:: <code>
##   Sets HTTP response status code.
##   NOTE: If any content was already returned this function does not work.
##
nuweb.status() {
  local code=$1;
  local message=$2;
  echo "HTTP/1.1 $code $message"
}

## nuweb.content_type:: <content-type>
##  Sets HTTP response content type
##  NOTE: If any content was already returned this function does not work.
nuweb.content_type() {
  echo "Content-Type: $@"
}

## nuweb.redirect:: [--relative] <path>
##
nuweb.redirect() {
  local prefix="";
  if [ "$1" == "--relative" ]; then
    shift;
    prefix="$(dirname "$SCRIPT_NAME")/"
  fi

  echo Location: "$prefix$@"
  echo
  echo
}

## nuweb.redirect.exec::
##
nuweb.redirect.exec() {
  if [ "$1" == "--relative" ]; then
    args="--relative";
    shift;
  fi
  fn=$1; shift;
  nuweb.redirect $args $($fn $@)
}

## nuweb.http.query.var:: <param> [defaultValue]
##   Reads HTTP query string from variable *QUERY_STRING*, parses it and returns
##   value of parameter *param* or *defaultValue*.
##
##   NOTE: Currently does not perform urldecode
nuweb.http.query.var() {
  local to_read=$1;
  local line_separrated=$(sed "s/&/\n/g" <<< $QUERY_STRING)

  while IFS="=" read -r var value; do
    if [ "$var" = "$to_read" ]; then
      echo "$value"
      return;
    fi
  done <<< "$line_separrated"
  echo $2
}

## nuweb.http.query.to_var::
##
nuweb.http.query.to_var() {
  local line_separrated=$(sed "s/&/\n/g" <<< $QUERY_STRING)
  while IFS="=" read -r var value; do
    declare -x "nuweb_QUERY_$var"="$value"
  done <<< "$line_separrated"
}
