@prefix statement nux.nuxsh.statement
@prefix block nux.nuxsh.block

@namespace nuweb.html.syntax {

  function :statement {
    :start "$@"
    :end "$@"
  }

  function :start tag indent args {
    echo -n "${indent}echo '<$tag'";

    nux.log debug "Args are '$args'";
    set -- $args
    local attr="";
    local classes="";
    for arg; do
      if [ -n "$attr" ] ; then
        echo -n $arg"'\"'"
        attr="";
      else
        case "$arg" in
          @*)
            attr="${arg#@}";
            echo -n " '${attr}=\"'"
            ;;
          .*) classes="${classes}${arg//./ }";;
          *)
          nux.dsl.process.fail "unknown argument '$arg'  '$line' "
          return 1;
          ;;
        esac
      fi
    done
    if [ -n "$classes" ] {
      echo -n " 'class=\"'$classes'\"'"
    }
    echo " '>'";
  }

  function :end tag indent {
    echo "${indent}echo '</$tag>'";
  }

  function :element {
    for tag in "$@" ; do
      block:rewrite.call nuweb.html.dynamic.$tag "nuweb.html.element $tag" "nuweb.html.element.end $tag"
      block:rewrite.func nuweb.html.$tag "nuweb.html.syntax.start $tag" "nuweb.html.syntax.end $tag"
      statement:rewrite.func nuweb.html.$tag "nuweb.html.syntax.statement $tag"
      statement:rewrite.call nuweb.dynamic.$tag "nuweb.html.element --close $tag"


    done
  }

  :element html body head title
  :element style link meta script
  :element header main nav

  :element span div p pre
  :element a img

  :element b i strong small

  :element h1 h2 h3 h4 h5 h6

  :element form input submit button textarea select label
}
