;;; add-hooks.el --- Functions for setting multiple hooks

;; Copyright (C) 2017 Nick McCurdy

;; Author: Nick McCurdy <nick@nickmccurdy.com>
;; Created: 22 Jan 2017
;; Version: 3.1.1
;; Package-Version: 20171217.108
;; Package-Commit: a1043b7cdb1ea98055a2c99f8d37584a553ca362
;; Keywords: lisp
;; Homepage: https://github.com/nickmccurdy/add-hooks

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the gnu general public license as
;; published by the free software foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; without any warranty; without even the implied warranty of
;; merchantability or fitness for a particular purpose.  see the gnu
;; general public license for more details.

;; You should have received a copy of the gnu general public license
;; along with gnu emacs; see the file copying.  if not, write to the
;; free software foundation, inc., 59 temple place - suite 330,
;; boston, ma 02111-1307, usa.

;;; Commentary:

;; Typically, you would need to call `add-hook' multiple times with
;; similar arguments to declare multiple functions for one hook, or
;; vice versa.  `add-hooks-pair' is a variant that takes multiple
;; hooks or functions that apply to each other.  The `add-hooks'
;; function tidies up duplicate hook and function names further into a
;; single declarative call (inspired by the `bind-key' package).

;; If you're using `use-package', use its `:hook' keyword instead, which has a
;; similar syntax while establishing autoload definitions and supporting
;; deferred loading.

;;; Code:

(defun add-hooks-listify (object)
  "If OBJECT is a list and not a function, return it, else wrap it in a list."
  (if (and (listp object)
           (not (functionp object)))
      object
    (list object)))

(defun add-hooks-normalize-hook (hook)
  "If HOOK is a symbol, ensure `-hook' is appended, else return HOOK itself."
  (if (and (symbolp hook)
           (not (string-match "-hook$" (symbol-name hook))))
      (intern (concat (symbol-name hook) "-hook"))
    hook))

;;;###autoload
(defun add-hooks-pair (hooks functions)
  "Call `add-hook' for each combined pair of items in HOOKS and FUNCTIONS.

HOOKS can be a symbol or a list of symbols representing hook
variables (the `-hook' suffix is implied).  FUNCTIONS can be a
symbol, a lambda, or a list of either representing hook
functions.  If lists are used, a function can be added to
multiple hooks and/or multiple functions can be added to a hook.

Example:

  ELISP> (add-hooks-pair '(css-mode sgml-mode) 'emmet-mode)
  nil
  ELISP> css-mode-hook
  (emmet-mode)
  ELISP> sgml-mode-hook
  (emmet-mode)"
  (dolist (hook (mapcar 'add-hooks-normalize-hook (add-hooks-listify hooks)))
    (dolist (function (add-hooks-listify functions))
      (add-hook hook function))))

;;;###autoload
(defun add-hooks (pairs)
  "Call `add-hooks-pair' on each cons pair in PAIRS.

Each pair has a `car' for setting hooks and a `cdr' for setting
functions to add to those hooks.  Pair values are passed to the
HOOKS and FUNCTIONS arguments of `add-hooks-pair', respectively.

Usage:

  (add-hooks ((HOOKS . FUNCTIONS)...))

Example:

  ELISP> (add-hooks '(((css-mode sgml-mode) . emmet-mode)))
  nil
  ELISP> css-mode-hook
  (emmet-mode)
  ELISP> sgml-mode-hook
  (emmet-mode)"
  (dolist (pair pairs)
    (add-hooks-pair (car pair) (cdr pair))))

(provide 'add-hooks)
;;; add-hooks.el ends here
