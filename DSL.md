# NUX DSL Engine

The DSL engine provides a foundation for building domain-specific languages in bash. Languages are defined purely in regex patterns and callback functions — no parser generators or ASTs involved. A file is parsed line-by-line against a ordered list of regex patterns, with each match triggering a callback to output transformed text.

## Core Concepts

### Pattern Matching

Each language is a sequence of patterns. Every line of input is tested against all patterns in order; the first match wins:

```sh
if [[ "$line" =~ $pattern ]]; then
  .gen.parser.$match_type.process
  break
fi
```

A pattern consists of:
- A regex string — the bash regular expression to match against
- Capture group mappings — assigns `BASH_REMATCH[$N]` values to meaningful variable names
- A plan function — called during compilation to produce transformed output
- A highlight function — called during syntax highlighting for terminal output

### Language Definition

A language is defined by a function that calls `.match` to register patterns. The function is called in a subshell during execution, so all `.match` calls populate shared arrays:

```sh
my.language.def() {
  .match.line task "@command +$args?( *)(\{)" \
    keyword indent args syntax - - - - - indent2 syntax2
  .match.line block_end '(\})' syntax
  .highlight keyword cyan
}
```

Calling `.match` registers three things:
1. Adds an entry to `$_gen_parser_types` — the ordered list of pattern types
2. Stores the regex in `_gen_parser_pattern_$type`
3. Defines `.gen.parser.$type.process` — assigns BASH_REMATCH groups to variables, then dispatches `.match.$type.$action`
4. Defines `.match.$type.highlight` — for terminal colorization

### Action Modes

The engine supports two modes controlled by an `$action` parameter:

| Mode | Description |
|------|-------------|
| `plan` | Generates transformed source code (output goes to file/stdout) |
| `process` | Generates default passthrough for unmatched lines |

A `.plan` function emits bash code. A `.process` function echoes the original line. If neither is defined, the default plan echoes the line unchanged, and the default process echoes the line unchanged.

### Pattern Callbacks

Each pattern type can define zero or more callback functions following these conventions:

```
.action.<action>().          -- generic action handler, never called automatically (manual dispatch)
.match.<type>.<action>().    -- called on match, where <action> is plan or process
.block.<identifier>.<action>(). -- called on block start/end for a specific block identifier
.block.<action>().           -- called if no specific block handler is found
```

Dispatched via `nux.exec.or`:

```sh
nux.exec.or .block.$identifier.start.plan .block.start.plan
```

The engine also supports catch-all callbacks:
- `.match._unmatched.plan` / `.match._unmatched.process` — called when no pattern matches a line
- `.process.plan` / `.process.process` — default fallback for any pattern that has no plan

## Compilation

### Cache-Based Compilation

`nux.dsl.exec` handles the full compile-and-load cycle:

```sh
nux.dsl.exec <language_func> <source_file> <cached_file>
```

1. Checks if source is newer than the cached file via timestamp comparison (`-ot`)
2. If recompilation is needed, calls `nux.dsl.plan` which:
   - Creates temp file in the cache directory
   - Runs `nux.dsl.process plan $language $file` into the temp file
   - Atomically moves it into place as the cached file
3. If compilation fails, removes the temp file and returns non-zero
4. Sources the cached file

The cached file is sourced after compilation, so the output is just plain bash that runs at full shell speed.

### In-Memory Processing

For one-off processing without caching, use `nux.dsl.process` directly:

```sh
nux.dsl.process <action> <language_func> <file>
```

Runs the language function in a subshell, pipes each line through the parser loop, and outputs the result. Useful for highlighting or previewing a plan without writing to disk.

## Building a New DSL

The minimal implementation of a DSL looks like:

```sh
lang.mylang.def() {
  local comment='(( *)(#.*))?'
  local whitespace="([ ]*)"
  local args="([^ ]+)"

  .match.line() {
    local type="$1"
    local match="^( *)$2$comment$"
    shift; shift
    .match "$type" "$match" indent "$@" - indent_comment comment
  }

  # Register patterns with variable assignments
  .match.line comment ''
  .match.line block_start "([^ ]+)( +)$args( *)(\{)" \
    keyword indent args - - - - - indent2 syntax
  .match.line block_end '(\})' syntax

  # Callbacks — these functions define the transformation
  .match.block_start.plan() {
    echo "${indent}echo \"entered ${keyword}\""
    .block.push $keyword
  }

  .block.<identifier>.end.plan() {
    echo "${indent}echo \"exited ${keyword}\""
    .block.pop
  }

  .match._unmatched.plan() {
    echo "$indent$line"
  }
}
```

Key files that exercise this pattern: `inc/nux/nuxsh.inc.sh` (nuxsh DSL), `inc/dsl/nuxfs.dsl` (filesystem DSL, uses older nux.dsl API).