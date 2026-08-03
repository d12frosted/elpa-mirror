promptu provides a transient menu that composes an LLM prompt from
user-customizable building blocks.

The opposite of impromptu: composed, not off-the-cuff.

Usage:

  M-x promptu

Pick blocks one at a time; the menu stays open and shows a live preview
as the prompt is built.

Press `RET` to copy the composed prompt to the kill ring, then paste it into
your agent (e.g. `agent-shell`) or anywhere else.

See the README for full usage instructions, or just start using promptu!

Example:

Pressing `r c - P` triggers the built-in blocks `review`, `commit`, then arms
`-` and adds a negated `push`.  This composes (with the default separator) a
bulleted prompt:

  - review your changes
  - commit
  - don't push
