@syntax nuweb/html

@prefix statement nux.nuxsh.statement
@prefix block nux.nuxsh.block
@prefix hs nuweb.html.syntax

nux.use nuweb/html.syntax

@namespace nuweb.mdlio.syntax {
  function :element name tag {
    block:rewrite.call nuweb.mdlio.tag.$name "nuweb.html.element $tag $@" "nuweb.html.element.end $tag"
    statement:rewrite.call nuweb.mdlio.tag.$name "nuweb.html.element --close $tag $@"
  }

  function :block-as-function fqn {
    block:rewrite.call $fqn "function $fqn {" "}"
  }

  function :statement-as-echo-function fqn {
    statement:rewrite.call $fqn "function $fqn() { echo " ";}"
  }

  :element card div .mdl-card.mdl-shadow--2dp
  :element card-media div .mdl-card_media
  :element card-title div .mdl-card_title

  :element nav nav .mdl-navigation


  :block-as-function app.name
  :block-as-function app.main
  :block-as-function app.content
  :block-as-function app.drawer
  :block-as-function app.page-title
  :block-as-function app.title
  :block-as-function app.scripts
  :block-as-function app.template-main
  :block-as-function app.routes

  #:statement-as-echo-function app.page-title
  #:statement-as-echo-function app.content
}

function .block.app.start.plan {
  identifier=app .match.namespace_block_start.plan
}

function .block.app.end.plan {
  .block.rule.namespace.end.plan
}
