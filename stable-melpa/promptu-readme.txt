promptu provides a transient menu that composes an LLM prompt from
user-customizable building blocks.

Usage:

  M-x promptu

Pick blocks one at a time using their associated keys.  The transient stays
open and shows a live preview as the prompt is built.

Press `RET` to copy the composed prompt to the kill ring, then paste it into
your agent (e.g. `agent-shell`) or anywhere else.

See the README for full usage instructions, or just start using promptu!

Example:

Pressing `r c - P` triggers the built-in blocks `review`, `commit`, arms
negation, and finally adds a negated `push`.  This composes a bulleted
prompt:

  - review your changes
  - commit
  - don't push
