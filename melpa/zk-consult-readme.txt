This package offers several integrations of Consult with zk:


1. Two functions as alternatives to the default `zk-grep' functions:
`zk-consult-grep' and `zk-consult-grep-tag-search'.  Instead of displaying
search results in a `grep' buffer, these functions display search results
using Consult.

  To use these alternative functions, set one or both of the following variables:
  (setq zk-grep-function 'zk-consult-grep)
  (setq zk-tag-grep-function 'zk-consult-grep-tag-search)


2. Two ways of accessing a list of currently open notes via `consult-buffer':
first through `consult-buffer' itself, accessible via narrowing with the
'z' key; second, as alternative to the command `zk-current-notes', such
that it brings up the Consult buffer source directly.

  To add the zk Consult buffer source to `consult-buffer-sources', evaluate:
  (add-to-list `consult-buffer-sources 'zk-consult-source 'append)

  To set the alternative `zk-current-note' function, evaluate:
  (setq zk-current-notes-function 'zk-consult-current-notes)


3. Note previews when selecting a zk-file in the minibuffer.

  To implement note previews, evaluate:
  (setq zk-select-file-function 'zk-consult-select-file)

  NOTE: The list of functions for which previews will be shown can be
  customized by amending the functions listed in the variable
  `zk-consult-preview-functions'.


To load this package, put `zk-consult.el' into your load path, load Consult,
and evaluate the following:

(with-eval-after-load 'consult
  (with-eval-after-load 'zk
    (require 'zk-consult)))
