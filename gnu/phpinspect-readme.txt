PHPInspect is a minor mode that provides code intelligence for PHP in Emacs.
At its core is a PHP parser implemented in Emacs Lisp.  PHPInspect comes with
backends for `completion-at-point`, `company-mode` and `eldoc`.  A backend
for `xref` (which provides go-to-definition functionality) is planned to be
implemented at a later date.

See docstrings for elaborate documentation on how to use the mode, starting
with `phpinspect-mode'. Also see M-x customize-group RET phpinspect RET.