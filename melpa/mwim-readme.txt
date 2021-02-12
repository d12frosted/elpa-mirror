MWIM stands for "Move Where I Mean".  This package is inspired by
<http://www.emacswiki.org/emacs/BackToIndentationOrBeginning>.  It
provides commands to switch between various positions on the current
line (particularly, to move to the beginning/end of code, line or
comment).

To install the package manually, add the following to your init file:

  (add-to-list 'load-path "/path/to/mwim-dir")
  (autoload 'mwim "mwim" nil t)
  (autoload 'mwim-beginning "mwim" nil t)
  (autoload 'mwim-end "mwim" nil t)
  (autoload 'mwim-beginning-of-code-or-line "mwim" nil t)
  (autoload 'mwim-beginning-of-line-or-code "mwim" nil t)
  (autoload 'mwim-beginning-of-code-or-line-or-comment "mwim" nil t)
  (autoload 'mwim-end-of-code-or-line "mwim" nil t)
  (autoload 'mwim-end-of-line-or-code "mwim" nil t)

Then you can bind some keys to some of those commands and start
moving.  See README in the source repo for more details.
