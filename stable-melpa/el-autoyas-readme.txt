
* About
el-autoyas is a small complement to yasnippet for emacs-lisp-mode.  It
provides automatically created yasnippets from eldoc argument lists.
* Requirements
 - [[https://github.com/capitaomorte/yasnippet][yasnippet]]
 - eldoc
* Usage
 - To expand the snippet, type the function name or abbrevation and
   then press `TAB'
 - To jump to the next field press `TAB'.  If you did not change the
   field, either the parameter is kept, or replaced with `nil' or
   nothing depending on the argument list.
 - *NOTE* To use some of the more common functions, you may wish to
   delete all the emacs-lisp snippets in the snippets directory.
* Limitations
 - Currently does not support common lisp key functions
 - Unclear if nested snippet expansion is supported.
* Loading el-autoyas in ~/.emacs
You may use marmalade-repo and ELPA to install el-autoyas, or put it
into your load-path and put the following in =~/.emacs=:


    (require 'el-autoyas)

*Hook run on package load.
Suggestion: Add `el-autoyas-install'.
*Hook run on package load.
Suggestion: Add `el-autoyas-install'.
*Hook run on package load.
Suggestion: Add `el-autoyas-install'.

*** yas-backward-compatability
Yasnippet backward compatability functions used in el-autoyas.el

Value: ((yas/expand-snippet yas-expand-snippet)
 (yas/modified-p yas-modified-p)
 (yas/moving-away-p yas-moving-away-p)
 (yas/text yas-text)
 (yas/skip-and-clear-or-delete-char yas-skip-and-clear-or-delete-char)
 (yas/snippets-at-point yas--snippets-at-point)
 (yas/update-mirrors yas--update-mirrors)
 (yas/fallback-behavior yas-fallback-behavior)
 (yas/minor-mode yas-minor-mode))


*Hook run on package load.
Suggestion: Add `el-autoyas-install'.

*** yas-backward-compatability
Yasnippet backward compatability functions used in el-autoyas.el

Value: ((yas/expand-snippet yas-expand-snippet)
 (yas/modified-p yas-modified-p)
 (yas/moving-away-p yas-moving-away-p)
 (yas/text yas-text)
 (yas/skip-and-clear-or-delete-char yas-skip-and-clear-or-delete-char)
 (yas/snippets-at-point yas--snippets-at-point)
 (yas/update-mirrors yas--update-mirrors)
 (yas/fallback-behavior yas-fallback-behavior)
 (yas/minor-mode yas-minor-mode))


*Hook run on package load.
Suggestion: Add `el-autoyas-install'.

*** yas-backward-compatability
Yasnippet backward compatability functions used in el-autoyas.el

Value: ((yas/expand-snippet yas-expand-snippet)
 (yas/modified-p yas-modified-p)
 (yas/moving-away-p yas-moving-away-p)
 (yas/text yas-text)
 (yas/skip-and-clear-or-delete-char yas-skip-and-clear-or-delete-char)
 (yas/snippets-at-point yas--snippets-at-point)
 (yas/update-mirrors yas--update-mirrors)
 (yas/fallback-behavior yas-fallback-behavior)
 (yas/minor-mode yas-minor-mode))


*Hook run on package load.
Suggestion: Add `el-autoyas-install'.

*** yas-backward-compatability
Yasnippet backward compatability functions used in el-autoyas.el

Value: ((yas/expand-snippet yas-expand-snippet)
 (yas/modified-p yas-modified-p)
 (yas/moving-away-p yas-moving-away-p)
 (yas/text yas-text)
 (yas/skip-and-clear-or-delete-char yas-skip-and-clear-or-delete-char)
 (yas/snippets-at-point yas--snippets-at-point)
 (yas/update-mirrors yas--update-mirrors)
 (yas/fallback-behavior yas-fallback-behavior)
 (yas/minor-mode yas-minor-mode))


*Hook run on package load.
Suggestion: Add `el-autoyas-install'.

*** yas-backward-compatability
Yasnippet backward compatability functions used in el-autoyas.el

Value: ((yas/expand-snippet yas-expand-snippet)
(yas/modified-p yas-modified-p)
(yas/moving-away-p yas-moving-away-p)
(yas/text yas-text)
(yas/skip-and-clear-or-delete-char yas-skip-and-clear-or-delete-char)
(yas/snippets-at-point yas--snippets-at-point)
(yas/update-mirrors yas--update-mirrors)
(yas/fallback-behavior yas-fallback-behavior)
(yas/minor-mode yas-minor-mode))


*Hook run on package load.
Suggestion: Add `el-autoyas-install'.

*** yas-backward-compatability
Yasnippet backward compatability functions used in el-autoyas.el

Value: ((yas/expand-snippet yas-expand-snippet)
(yas/modified-p yas-modified-p)
(yas/moving-away-p yas-moving-away-p)
(yas/text yas-text)
(yas/skip-and-clear-or-delete-char yas-skip-and-clear-or-delete-char)
(yas/snippets-at-point yas--snippets-at-point)
(yas/update-mirrors yas--update-mirrors)
(yas/fallback-behavior yas-fallback-behavior)
(yas/minor-mode yas-minor-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
