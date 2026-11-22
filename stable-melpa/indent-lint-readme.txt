Indent Lint checks a buffer against its major mode's indentation rules.
It indents a copy in a separate Emacs process, then displays the
differences without editing the original buffer.

Run M-x indent-lint to check the current buffer.  Use indent-lint-batch
for command-line checks or enable flycheck-indent to report indentation
mismatches through Flycheck.
