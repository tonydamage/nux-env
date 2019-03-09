function nuweb.html.get {
	echo ${NUWEB_HTML_ARRAY[${#NUWEB_HTML_ARRAY[@]}-1]}
}

function nuweb.html.offset {
	echo "${NUWEB_HTML_OFFSET[@]}"
}

function nuweb.html.pop {
  unset NUWEB_HTML_ARRAY[${#NUWEB_HTML_ARRAY[@]}-1]
  unset NUWEB_HTML_OFFSET[${#NUWEB_HTML_OFFSET[@]}-1]
}

function nuweb.html.push {
	local value="$1"
  NUWEB_HTML_OFFSET[${#NUWEB_HTML_OFFSET[@]}]="  "
  NUWEB_HTML_ARRAY[${#NUWEB_HTML_ARRAY[@]}]="$value"
}

function e {
  nuweb.html.element --close "$@"
}

function e+ {
  nuweb.html.element "$@"
}

function +e {
  nuweb.html.element "$@"
}

function -e {
  nuweb.html.element.end "$@"
}


function e- {
  nuweb.html.element.end "$@"
}

nw.head() {
  :
}

function e.link() {
  nuweb.html.element --single link @rel "$1" @href "$2"
}

function h.a() {
  :
}

nw.script() {
  :
}

nuweb.html.element.spec() {
  local content_as_args="";
  if [ "$1" = "--content-as-args" ]; then
    content_as_args="yes";
    shift;
  fi
  local target="$1"; shift;
  local element="$1"; shift;
  local classes="";
  local attrs="";
  local attr="";
  local content="";
  for arg in "$@" ; do
    if [ -n "$attr" ] ; then
      attrs="$attrs $attr=\"$arg\""
      attr="";
    else
      case "$arg" in
        @*) attr="${arg#@}";;
        .*) classes="${classes}${arg//./ }";;
        *) content="$content $arg";;
      esac
    fi
  done
  if [ -n "$classes" ] ; then
    classes=" class=\"$classes\" ";
  fi
  if [ -n "$content_as_args" ]; then
    $target $content;
  else
    $target;
  fi
}

nuweb.html.element() {
  local type="pair";
  case "$1" in
    --single) type="single" ; shift;;
    --close) type="close" ; shift;;
  esac

  nuweb.html.element.spec nuweb.html.element.$type "$@"

}

nuweb.html.element.single() {
  #offset=$(nuweb.html.offset)
  echo "<${element}${classes}${attrs} />"
}

nuweb.html.element.pair() {
  #local offset=$(nuweb.html.offset)
  echo "<${element}${classes}${attrs}>"
  if [ -n "$content" ]; then
    echo "  $content";
  fi
}

nuweb.html.element.close() {
  #local offset=$(nuweb.html.offset)
  echo "<${element}${classes}${attrs}>"
  if [ -n "$content" ]; then
    echo "  $content";
  fi
  echo "</$element>";
}


nuweb.html.element.end() {
  local element=$1
  #local offset=$(nuweb.html.offset)
  echo "</$element>"
}

e.alias() {
	local name="$1"; shift;
	local elem="$1"; shift;
	eval """
		+$name() {
			+e $elem "$@" \"\$@\"
		}

		-$name() {
			-e $elem
		}
	"""
}
