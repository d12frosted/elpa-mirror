A major mode based on scheme.  Also provides a REPL buffer.

To start editing lurk files, first run (or add to your init files)

  (require 'lurk-mode)

To get an interactive session, first make sure the custom variable
`lurk-executable' is set.

  M-x customize-variable RET lurk-executable

then set the value to be the location of the lurk binary (either
full path or leave as-is if it's installed on PATH).  Next run

  M-x lurk-repl

In a .lurk source file, you can run M-x lurk-eval-last-expression
to evaluate the given expression preceding point. The result will
be shown in the repl buffer.
