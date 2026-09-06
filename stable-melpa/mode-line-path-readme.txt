Display an abbreviated file path in the mode line.  Shorten long paths using
the values of short environment variable names (three characters or fewer) as
prefixes.  If a path is still too long, truncate it with an ellipsis.  The
idea is to abbreviate paths enough that it's practical to show them in the
mode line.

For example, if $e is "/home/alice/.emacs.d":

  /home/alice/.emacs.d/lisp/init.el => $e/lisp

Use the variable `mode-line-path' in `mode-line-buffer-identification', or
directly in `mode-line-format', to display abbreviated paths.  For example:

  (setq-default mode-line-buffer-identification
	   '("%b" " (" mode-line-path ")"))
