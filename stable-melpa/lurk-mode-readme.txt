A major mode based on scheme.  Also provides a REPL buffer.

To start editing lurk files, first run (or add to your init files)

  (require 'lurk-mode)

To get an interactive session, first make sure the custom variable
`lurk-executable' is set.

  M-x customize-variable RET lurk-executable

then set the value to be the full path to the lurk binary.  Next run

  M-x lurk-repl
