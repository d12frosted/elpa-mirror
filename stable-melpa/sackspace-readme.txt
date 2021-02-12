Install:
Put file into load-path and (require 'sackspace).

Usage:
(global-sackspace-mode 1)
See (describe-function 'sackspace-mode)

Support for other packages:
* Supports `subword-mode`, and `paredit-mode`.
  To disable this support change the "honor" customs in
  `M-x customize-group RET sackspace RET`.

* Supports `evil` directly by prohibiting edits in non-editing states if evil is enabled.

Limitations:
* Within `term-mode` `sacks/whitespace` won't work (it will delete the chars
  from the emacs buffer, but not from the terminal).
* C-<backspace> and S-<backspace> are not available in a terminal emacs

Homepage: http://github.com/cofi/sackspace.el
Git-Repository: git://github.com/cofi/sackspace.el.git

Known Bugs:
See http://github.com/cofi/sackspace.el/issues
