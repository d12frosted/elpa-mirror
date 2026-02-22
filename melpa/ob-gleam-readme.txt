Org Babel support for evaluating Gleam code blocks.

Gleam requires a full project structure to compile and run, so this
package creates a temporary Gleam project for each code block execution.

Supported header arguments:
  :results - output (default), silent
  :deps    - space-separated Hex package names
  :imports - space-separated module paths for auto-import
  :target  - compilation target (erlang, javascript); default erlang
