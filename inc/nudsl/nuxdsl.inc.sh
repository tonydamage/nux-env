nux.use nudsl/yanglike


lang.nuxdsl.strict.def() {
  lang.yanglike.def

  .keyword.plan() {
    nudsl.process.fail "undefined keyword: $keyword";
  }
  .block.start.plan() {
    nudsl.process.fail "undefined block: $keyword";
  }
  .block.end.plan() {
    echo "${indent}end${keyword}";
  }

  .match._unmatched.plan() {
    nudsl.process.fail "invalid syntax: $line";
  }
}

lang.nuxdsl.def() {
  lang.nuxdsl.strict.def

  .keyword.plan() {
    echo "$indent$keyword $args";
  }
  .block.start.plan() {
    .keyword.plan
  }
  .block.end.plan() {
    echo "${indent}end${keyword}";
  }

  .match._unmatched.plan() {
    echo "$line";
  }

}

.default.plan() {
  echo "$indent$keyword $args";
}
.blockend.plan() {
  echo "${indent}end${keyword}";
}

.block() {
  eval """
    .block.$1.start.plan() {
      .default.plan
    }
    .block.$1.end.plan() {
      .blockend.plan
    }
    .keyword.$1.plan() {
      .default.plan
    }
"""
}

.keyword() {
  eval """
    .keyword.$1.plan() {
      .default.plan
    }
"""
}
