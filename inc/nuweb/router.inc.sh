

##
## #Path specification format
##
## Path specification is written as standard path:
##      *path_spec*[?*query_spec*]
## Where:
##    *path_spec* is standard HTTP path separated with */* and following special
##    characters:
##       **@**  - Required path component, it is captured as positional argument
##       **@+** - Required path component, capture current and all subsequent
##            components as path. Path is positional argument.
##    *query_spec* is optional and allows for matching values of query arguments
##    or transforming query arguments into positional arguments. It is written
##    in form "?arg1=valueDef&arg2=valueDef"
##    Following special characters are supported:
##       **@**  - Required argument, capture value as positional argument.
##       **?@** - Optional argument, capture value as positional argument.
##
##
nuweb.router.tryexec.concrete() {
  method="$1";
  full_spec="$2";
  func="$3";
  shift; shift; shift;
  if [ "$REQUEST_METHOD" != "$method" ]; then
    return 1;
  fi

  path_spec=${full_spec%%\?*}
  query_spec=${full_spec#$path_spec}
  query_spec=${query_spec#\?}

  nux.log trace  "Checking Path Spec: '$path_spec', Query Spec: '$query_spec' Function:$func Additional Args:$@" >&2

  IFS='/' read -ra spec_components <<< "$path_spec"
  i=0;path_args="";path_c="";
  for path in "${PATH_COMPONENTS[@]}" ; do
    spec=${spec_components[$i]}
    if [ "$spec" == "@+" ]; then
      consume="consume"
    fi
    if [ -n "$consume" ]; then
      path_c="$path_c/$path"
    elif [ "$spec" == "@" ]; then
      path_args="$path_args $path";
    elif [ "$spec" != "$path" ] ; then
      return 1
    fi
    let i=$i+1
  done
  if [ $i -lt "${#spec_components[@]}" ] ; then
    return 1;
  fi
  if [ -n "$query_spec" ]; then
  IFS='&' read -ra query_components <<< "$query_spec"
  for varDef in "${query_components[@]}" ; do
    IFS='=' read -r var valueDef <<< "$varDef"
    value=$(nuweb.http.query.var $var)
    #echo $var $valueDef $value >&2;
    if [ "$valueDef" == "?@" ]; then
      query_args="$query_args $value"
    else
      if [ -z "$value" ]; then
        #echo "$def $value is empty." >&2;
        return 1;
      elif [ "$valueDef" == "@" ]; then
        query_args="$query_args $value"
      elif [ "$value" != "$valueDef" ]; then
        #echo "$def $value != $valueDef" >&2;
        return 1;
      fi
    fi
  done
  fi
  path_c=$(dirty.url.decode "$path_c")
  nuweb.http.query.with_env nuweb.http.post.with_env $func "$@" $path_args "$path_c" $query_args
  exit 0

}

nuweb.router.get() {
  nuweb.router.tryexec.concrete GET "$@";
}

nuweb.router.post() {
  nuweb.router.tryexec.concrete POST "$@";
}

##
## nuweb.router.exec:: <definition> [path]
##  Parses *path* and executes functions as defined in *definition*.
##  *definition* is name of *function* which contains specific route patterns.
##  *path* is HTTP path, for which router should parse arguments. If path is
##  not specified, *PATH_INFO* will be used instead.
##
nuweb.router.exec() {
  local definition="$1";
  local path="$2";

  if [ -z "$path" ] ; then
    path="$PATH_INFO"
  fi
  if [ -z "$path" ] ; then
    path="/"
  fi

  nux.log debug "Method: '$REQUEST_METHOD' Path: '$path'"
  IFS='/' read -ra PATH_COMPONENTS <<< "$path"

  $definition

  nuweb.status 404 NOT FOUND
  nuweb.content_type text/plain
  echo """

    Status:404
    Path $PATH_INFO Not found.

  """
}
