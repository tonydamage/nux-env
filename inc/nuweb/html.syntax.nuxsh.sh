@prefix statement nux.nuxsh.statement
@prefix block nux.nuxsh.block

@namespace nuweb.html.syntax {

  function :element {
    for tag in "$@" ; do
      block:rewrite.call nuweb.html.$tag "nuweb.html.element $tag" "nuweb.html.element.end $tag"
      statement:rewrite.call nuweb.html.$tag "nuweb.html.element --close $tag"
    done
  }

  :element html body head title
  :element style link meta script
  :element header main nav

  :element span div p pre
  :element a img

  :element h1 h2 h3 h4 h5 h6

  :element form input submit button textarea select label
}
