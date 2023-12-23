Navigate Org headings via tree outline in a side window.

Inspired by and modeled on `org-sidebar-tree' from org-sidebar by Adam
Porter (@alphapapa) and `embark-live' from Embark by Omar Antolin
(@oantolin).

To install, place file on your load-path
and include this in your init file:
(require 'org-side-tree)

To use, Open an Org file and call M-x `org-side-tree'.

Regarding support for non-Org files:

This package is generally functional in buffers that use `outline-mode' or
`outline-minor-mode'. However, the depth and quality of
support/functionality in these modes is highly dependent on what the
buffer-local value of `outline-regexp' is. Therefore, individual
experience may vary. Use advisedly.

For example, in `emacs-lisp-mode', consider setting `outline-regexp' as
follows: (setq-local outline-regexp ";;;\\(;* [^ \t\n]\\)")

To set this automatically for every elisp buffer, add the following lines
to your init file:

(add-hook 'emacs-lisp-mode-hook
    (lambda () (setq-local outline-regexp ";;;\\(;* [^   \t\n]\\)")))
(add-hook 'emacs-lisp-mode-hook 'outline-minor-mode)
