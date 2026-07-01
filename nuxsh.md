# nuxsh

nuxsh is a source-to-source annotation DSL for bash scripts. It transforms annotated code into plain bash at load time, enabling shorter function names, lexical scoping, and convenient prefix aliasing. Scripts are compiled on first use, cached on disk, then sourced — adding zero runtime overhead.

## Shebang

Scripts using nuxsh must use one of these shebangs:

```sh
#!/usr/bin/env nuxsh
#!/usr/bin/env nuxr-nuxsh
```

Both call `nuxr-nuxsh`, which compiles the script file with `nux.nuxsh.use` then invokes the nux-runner dispatcher (`nuxr.main`).

## Annotations

### @command

Declares a callable CLI task:

```
@command taskname [<arg1>, <arg2>, ...] { ... }
```

Becomes:

```sh
task.taskname() {
  nux.log trace task.taskname: invoked
  local arg1="'$1'"; shift
  local arg2="'$2'"; shift
  nux.log trace "  additional args: " "$@";
  ... user code ...
}
```

The parser extracts argument names from the declaration and generates code that assigns each positional parameter to a local variable with a corresponding `shift`. If no arguments are declared, the body receives the original `$@`.

Inside a `@namespace`, `:`-prefixed identifiers resolve to the namespace-prefixed function name:

```sh
@namespace task. {
  function :status {   →  task.status()
    ...
  }
}
```

### @namespace

Opens a lexical scoping block. Inside the block, unprefixed identifiers resolve against the namespace prefix:

```
@namespace identifier. {
  ... code ...
}
```

```sh
@namespace nuxr. {
  function :run ARGS {    →  nuxr.run()
    ... check:argument exists { }   →  if nux.check.argument exists; then ...
    ...
  }
}
```

When the block closes with `}`, the namespace resets to the previous scope. A `.task.` suffix convention is used for nux-runner task functions, mapping `@namespace task.` → `task.<taskname>` functions.

Inside `.namespace` blocks, a second namespace can be nested by defining tasks with a dot separator:

```sh
@namespace nuxr.task.help. {
  function : topic {    →  nuxr.task.help.topic()
  }
}
```

This maps `: topic` → `nuxr.task.help.topic`. Note the leading space after `:` — it's required by the parser to distinguish the argument from the function name.

### @prefix

Defines short-form prefix aliasing. A `@prefix` can be a variable reference or inline text:

```
@prefix check nux.check.
@prefix help nux.help.
@prefix fs nux.fs.
```

This registers internal variables like `_import_prefix_check='nux.check.'`. During compilation, any statement matching `$prefixed_id` (`[^= :]*:$identifier`) will prepend the registered prefix:

```sh
check:function exists    →  nux.check.function exists
check:file dir           →  nux.check.file dir
```

Prefixes also work inside `if` conditionals:

```sh
if check:function task.mytask {
  ...
}
```

→ compiles to:

```sh
if nux.check.function task.mytask ; then
  ...
fi
```

The `@prefix` value is treated as a variable value via `eval`, so it can contain spaces, special characters, or other content, but this means malformed content can produce broken code.

### if statements

The `if` block is handled natively by the nuxsh compiler:

```sh
if check:function task.mytask {
  echo "exists"
}
```

→ compiles to:

```sh
if nux.check.function task.mytask ; then
  nux.log trace "  additional args: " "$@";
  echo "exists"
fi
```

The compiler:
1. Pushes `lang.if` as the block type
2. Resolves prefix-qualified identifiers (`check:function` → `nux.check.function`)
3. Emits `if <resolved_identifier> <args> ; then`
4. On block close, emits `fi`

## Comment-Based Help Rendering

The framework extracts documentation from `##` comment blocks and renders them with colorized output via `nux.help.shelldoc`. See [DSL.md](DSL.md) for the rendering/formatting spec.

### Script Header Documentation

A top-level `##` comment block before all code describes the script as a whole:

```sh
## linky - Symlink management utility
##
## Provides tools for managing symbolic links, including converting absolute
## paths to relative ones and safely removing symlink chains along with their
## sources.
@command relativize {
  ...
}
```

When `nux help` is invoked with no task argument, `nux.help.comment` extracts these top-level `##` lines from the script and renders them.

### Task Documentation

A `##` comment block immediately before a task declaration describes that specific task:

```sh
##   relativize:: <link>
##   Converts absolute symlinks to relative ones
##
@command relativize {
  ...
}
```

When `nux help relativize` is invoked, the framework locates the `## relativize::` block and extracts all `##` lines between that doc block and the code line (`@command` or `function` or `task.relativize`), then passes them through `nux.help.shelldoc`.

### Sub-Items in Documentation

Use `###` (indented double-hash) within a `##` block to document sub-items:

```sh
##   switch:: <storage> <path+>
##   Moves specified paths to named storage for a particular VFS.
###
###     The switch uses .vfs.sources file to determine the location of the
###     target directory and creates necessary directory structures.
###
###     FIXME: Switch does not support merging of directories
@command switch storage {
```

### Shelldoc Markup

Text between `##` markers is processed with a small Markdown-like subset:

| Syntax | Rendered As | Example |
|--------|-------------|---------|
| `word::` | **bold keyword** | `switch::` |
| `**text**` | **bold** | **DOES NOT MODIFY** |
| `*text*` | *italic* (colored) | *nix |
| `##` (top level) | White text | description paragraph |
| `###` (indented) | White text | sub-item paragraph |
| `#` (single hash) | **bold header** | # Title |

The `nux.help.shelldoc` function applies these via `sed`:

```sh
sed -r \
  -e "s/^## ?(.*)/${NC_White}\1${NC_No}/gI" \      # white
  -e "s/^# ?(.*)/${NC_Bold}\1${NC_No}/gI"           # bold
  -e "s/^([ a-z0-9._-]*)::/${NC_Bold}\1${NC_No}/gI" # bold keyword
  -e "s/\*\*([^*]*)\*\*/${NC_Bold}\1${NC_No}/gI"    # bold inline
  -e "s/\*([^*]*)\*/${NC_White}\1${NC_No}/gI"       # italic-like
  --
```

This is piped through `nux.help.comment` to extract and render docs from any source file.

## Compilation

Scripts with nuxsh annotations get compiled into plain bash and cached. See [DSL.md](DSL.md) for the compilation pipeline. The cache file path defaults to the source file appended with `.nuxr.nuxsh` (e.g., `bin/taskie.nuxr.nuxsh`), and lives in `cache/bin/` or `cache/inc/` depending on the context.

## Examples

### Minimal CLI Script

```sh
#!/usr/bin/env nuxsh

## mycli - A simple CLI tool
##

@namespace task. {
  function :hello {
    echo "hello world"
  }

  function :greet name {
    echo "hello $name"
  }
}
```

Run with:
```
$ nuxsh mycli hello
hello world

$ nuxsh mycli greet alice
hello alice
```

### Script with Prefixes and Namespace

```sh
#!/usr/bin/env nuxsh
## mark - File tagging system
##

nux.use nux/fs
nux.use nux/check
@prefix fs nux.fs.
@prefix check nux.check.

@namespace mark. {
  function :dir item {
    if  [ -n "$MARK_DIR" ]; then
      echo $MARK_DIR
    else
      fs:closest ".by" "$item"
    fi
  }

  function :root path {
    local dir=$(mark:dir "$path")
    echo "$dir/."
  }
}

@namespace nuxr.run. {
  function :additional TASK {
    if check:function "task.$TASK"; then
      task.$TASK "$@"
    else
      echo "Unrecognized task: $TASK"
    fi
  }
}
```

### Using if with Prefixes

```sh
@namespace mark. {
  function :mark root item mark {
    if check:file.symlink "$item"; then
      # Item is already a symlink, handle separately
    else
      # Create symlink normally
    fi
  }
}
```

→ compiles to:

```sh
mark.mark() {
  nux.log trace mark.mark: invoked
  local root="$1"
  local item="$2"
  local mark="$3"
  nux.log trace "  additional args: " "$@";
  if nux.check.file.symlink "$item"; then
    # Item is already a symlink, handle separately
  else
    # Create symlink normally
  fi
}
```

### Taskie Example (Backend Detection)

`bin/taskie` uses `@namespace`, `@prefix`, and `@command` to provide a multi-backend task tracker:

```sh
#!/usr/bin/env nuxsh

nux.use nux/fs
nux.use nux/repl

nux.use taskie/common
nux.use taskie/backend.github
nux.use taskie/backend.gogs
nux.use taskie/backend.dir

@command labels {
  with.backend $(backend.detect);
    backend.$backend.labels "$@";
  endwith.backend;
}

@command add {
  with.backend $(backend.detect);
    if ! backend.$backend.issue.exists "$@"; then
      ...
      backend.$backend.issue.add "$@";
    else
      nux.echo.error Issue already exists.
    fi
  endwith.backend;
}
```

### nuxr-nuxsh Internals

The `@namespace nuxr.run.` block in `inc/nuxr.nuxsh.sh` is loaded by every nuxsh script and provides the task dispatcher:

```sh
@namespace nuxr. {
  function :run TASK {
    if check:function "task.$TASK"; then
      task.$TASK "$@"
    elif check:function "nuxr.run.additional"; then
      nuxr.run.additional "$TASK" "$@"
    else
      echo "$NUX_SCRIPTNAME: Unrecognized task '$TASK'"
      return -1
    fi
  }
}
```

The `:`-prefixed `:run` maps to `nuxr.run` inside the `nuxr.` namespace.