
Major mode for editing TaskJuggler 3 project files (.tjp, .tji).
See https://taskjuggler.org for more information.

Features:
  - Syntax highlighting for all TJ3 keywords
  - Comment support for //, /* */, and # styles
  - String highlighting (double-quoted strings)
  - Date literal highlighting: YYYY-MM-DD[-hh:mm[:ss]]
  - Duration literal highlighting: 5d, 2.5h, 3w, etc.
  - Macro reference highlighting: ${MacroName}, $(ENV_VAR)
  - Indentation based on { } and [ ] block nesting depth (line and region)
  - Compilation support: compile-command pre-filled with tj3, navigable errors
  - Flymake integration: on-the-fly error checking via tj3
  - tj3man integration: C-c C-t m looks up keyword docs with completion
  - Defun navigation: C-M-a/C-M-e jump to block start/end
  - Block editing: C-M-h marks block (incl.  comments), C-c C-t n narrows to
    block, clone-block duplicates the current block
  - Block navigation: C-M-n/C-M-p move to next/prev sibling, C-M-u goes to
    parent block, C-M-d goes to first child
  - Block movement: M-<up>/M-<down> moves the current block up or down
  - Sexp movement: C-M-f/C-M-b treats a keyword block as a single sexp
  - Inline calendar picker: C-c C-t d opens an overlay calendar for editing
    date literals at point
  - Yasnippet integration: snippets from the bundled snippets/ directory
  - Evil mode integration: [[ and ]] bound to beginning/end-of-defun
