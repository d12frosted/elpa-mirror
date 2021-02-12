The main features of this mode are syntactic highlighting (enabled
with `font-lock-mode' or `global-font-lock-mode'), automatic
indentation and filling of comments.

This package has (only) been tested with GNU Emacs 21.4 (the latest
stable release).

Installation:

Put this file in a directory where Emacs can find it (`C-h v
load-path' for more info). Then add the following lines to your
Emacs initialization file:

   (add-to-list 'auto-mode-alist '("\\.Mod\\'" . oberon-mode))
   (autoload 'oberon-mode "oberon" nil t)
   (add-hook 'oberon-mode-hook (lambda () (abbrev-mode t)))

You may want to change the regular expression on the first line if
your Oberon files do not end with `.Mod'. You can also skip the
last line if you do not want automatic upcase conversion of
predefined words.

General Remarks:

Exported names start with `oberon-' of which the names mentioned in
the major mode convetions start with `oberon-mode'. Private names
start with `obn-'.

For sake of simplicity certain (sensible) assumptions are made
about Oberon program texts. If the assuptions are not satisfied
there is no guarantee that the mode will function properly. The
assumptions are:

* No nested unbalanced control statements on the same line, e.g.
`IF p THEN IF q THEN s END'.

* No one-line procedure definitions, e.g.

     PROCEDURE P; BEGIN END P;
