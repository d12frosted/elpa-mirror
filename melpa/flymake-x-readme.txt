
; flymake-x

Package that provides an easy way to define flymake checkers.

For example, a pycodestyle checker can be defined like this:

 (pycodestyle
   :class pipe
   :modes (python-mode)
   :command "pycodestyle -"
   :error-patterns
   ((:warning
     (bol file ":" line ":" column ": " (message (zero-or-more nonl)) eol)))

; Usage

Call `flymake-x-setup' once, and modify `flymake-x-checkers'.  See it's
documentation for details.

You can also load the included \\='flymake-x-sample-checkers\\=' library
which contains a few predefined checkers.

For easily defining new checkers, a helpful command is provided to display
the checker output, found diagnostics and other information:
`flymake-x-debug'.  It should be called with the name of a checker or it's
definition, as described in `flymake-x-checkers'.
