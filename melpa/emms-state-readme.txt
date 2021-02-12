This package provides a minor mode (`emms-state-mode') for displaying
description and playing time of the current track (played by EMMS) in
the mode line.  A typical mode line string would look like this (it
may be configured with `emms-state-mode-line-string' variable):

  ⏵ 1:19(5:14) Chopin - Waltz in a-moll, Op.34 No.2

To install the package manually, add the following to your init file:

  (add-to-list 'load-path "/path/to/emms-state-dir")
  (autoload 'emms-state-mode "emms-state" nil t)

This package is intended to be used instead of `emms-mode-line' and
`emms-playing-time' modes and it is strongly recommended to disable
these modes before enabling `emms-state-mode' (keep in mind that
these modes are enabled automatically if you use `emms-all' or
`emms-devel' setup function).
