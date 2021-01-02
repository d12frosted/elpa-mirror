Note: The interface used in this file requires CC Mode 5.30 or
later.

History:
0.9.9 - 2019-05-07
added support for YANG multiline string literals; contributed
by Tripp Lilley
0.9.8 - 2018-03-06
yet another autoload fix; contributed by Christian Hopps
0.9.7 - 2017-03-23
one more autoload fix
0.9.6 - 2017-03-21
autoload fix, tested with use-package
0.9.5 - 2017-02-13
autoload fix
0.9.4 - 2016-12-20
derive from prog-mode if available, otherwise nil
use proper syntax-table
0.9.3 - 2016-12-13
derive from nil
0.9.2 - 2016-12-13
derive mode from prog-mode in order to get correct hook behavior
0.9.1 - 2016-12-12
use define-derived-mode
yang-fill-paragraph now works in Emacs 23
0.9 - 2016-12-09
workaround Emacs bug #18845 (for 24.4+)
00.8 - 2016-10-27
rfc7950 compliant
added yang-fill-paragraph for better string fill
00.7 - 2016-03-15
draft-ietf-netmod-rfc6020bis-11 compliant
added support for new 1.1 keywords
00.6 - 2012-02-01
removed unused defcustom yang-font-lock-extra-types
made emacs24 to give a warning
00.5 - 2010-10-07
rfc6020 compliant
classify all keywords as decl-start gives better indentation
00.4 - 2010-04-30
draft-ietf-netmod-yang-12 compliant,
added instructions for Emacs 23
00.3 - 2009-12-19
draft-ietf-netmod-yang-09 compliant,
00.2 - 2008-11-04
draft-ietf-netmod-yang-02 compliant.
00.1 - 2007-11-14
Initial version, draft-bjorklund-netconf-yang-00 compliant.

Useful tips:

If you're using use-package, put this in your .emacs:
(use-package yang-mode
:ensure t)

Otherwise, put this in your .emacs:
(require 'yang-mode)

For use with Emacs 23, put this in your .emacs:
(autoload 'yang-mode "yang-mode" "Major mode for editing YANG modules."
t)
(add-to-list 'auto-mode-alist '("\\.yang$" . yang-mode))

Some users have reported other errors with Emacs 23, and have found
that removing the byte-compiled cc-mode.elc file fixes these problems.
(e.g. /usr/share/emacs/23.1/lisp/progmodes/cc-mode.elc)


For editing somewhat larger YANG modules, add this to your .emacs
(setq blink-matching-paren-distance nil)

Common YANG layout:
(defun my-yang-mode-hook ()
"Configuration for YANG Mode.  Add this to `yang-mode-hook'."
(if window-system
(progn
(c-set-style "BSD")
(setq indent-tabs-mode nil)
(setq c-basic-offset 2)
(setq font-lock-maximum-decoration t)
(font-lock-mode t))))

(add-hook 'yang-mode-hook 'my-yang-mode-hook)

Using the outline minor mode for YANG is very useful to get a
good overview of the structure of a module.

Put this in your .emacs:

(defun show-onelevel ()
"show entry and children in outline mode"
(interactive)
(show-entry)
(show-children))

(defun my-outline-bindings ()
"sets shortcut bindings for outline minor mode"
(interactive)
(local-set-key [?\C-,] 'hide-body)
(local-set-key [?\C-.] 'show-all)
(local-set-key [C-up] 'outline-previous-visible-heading)
(local-set-key [C-down] 'outline-next-visible-heading)
(local-set-key [C-left] 'hide-subtree)
(local-set-key [C-right] 'show-onelevel)
(local-set-key [M-up] 'outline-backward-same-level)
(local-set-key [M-down] 'outline-forward-same-level)
(local-set-key [M-left] 'hide-subtree)
(local-set-key [M-right] 'show-subtree))

(add-hook
'outline-minor-mode-hook
'my-outline-bindings)

(defconst sort-of-yang-identifier-regexp "[-a-zA-Z0-9_\\.:]*")

(add-hook
'yang-mode-hook
'(lambda ()
(outline-minor-mode)
(setq outline-regexp
(concat "^ *" sort-of-yang-identifier-regexp " *"
sort-of-yang-identifier-regexp
" *{"))))
