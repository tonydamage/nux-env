#!/usr/bin/env bash

nux.use nudsl/blocktrac

## # nudsl/yanglike - Basic skeleton for YANG-like languages

##
## yanglike is barebones support for development of YANG-like languages
## with two main concepts: blocks and simple statements.
##
## The syntax of language is following:
##
##    *statement* = <*block*> | <*simple*>
##    *block* = <*keyword*> [*arg*]* **{**
##      [*statement*]*
##    *}*
##    *simple* = <*keyword*> [*arg*]*;
##    *arg* = <*uarg*> | <*darg*> | <*sarg*>
##    *uarg* - unquoted argument
##    *sarg* - single quoted argument
##    *darg* - double quoted argument
##
##  Language support is basic with following restrictions:
##    - one statement per line


##
## lang.yanglike.def ::
##    Definition of *yanglike* language
##
lang.yanglike.def() {
  local comment='(( *)(#.*))?'
  local whitespace="([ ]*)"
  local uarg="([^ #\{\}\"'\"'\"';]+)";
  local sarg="('\"'\"'[^'\"'\"']+'\"'\"')";
  local darg='("[^"]*")';
  local args="((($uarg|$darg|$sarg) *)*)";
  .match.line() {
    local type="$1";
    local match="^( *)$2$comment$";
    shift;shift;
    .match "$type" "$match" indent "$@" - indent_comment comment;
  }

  .match.line comment ''
  .match.line block_end '(\})' \
      syntax
  .match.line block_start "([^ ]+)( +)$args( *)(\{)" \
      keyword indent2 args - - - - - indent3 syntax
  .match.line keyword "([^ ]+)( +)$args?( *)(;)"\
      keyword indent2 args - - - - - indent3 syntax


  .highlight keyword green
  .highlight syntax blue
  .highlight args yellow
  .highlight unmatched bg_red
}


.match.comment.plan() {
  nux.exec.optional .comment.plan
}


.match.keyword.plan() {
  #nux.log trace "Executing plan for ''$keyword'"
  nux.exec.or .keyword.$keyword.plan .keyword.plan
}
