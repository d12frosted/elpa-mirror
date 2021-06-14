;;; blackout.el --- Better mode lighter overriding -*- lexical-binding: t -*-

;; Copyright (C) 2018 Radon Rosborough

;; Author: Radon Rosborough <radon.neon@gmail.com>
;; Created: 12 Aug 2018
;; Homepage: https://github.com/raxod502/blackout
;; Keywords: extensions
;; Package-Version: 20200404.1550
;; Package-Commit: 8f7cd388abccdf25baeca99c07ef2dfe264e8f2f
;; Package-Requires: ((emacs "26"))
;; SPDX-License-Identifier: MIT
;; Version: 1.0

;;; Commentary:

;; Blackout is a package which allows you to hide or customize the
;; display of major and minor modes in the mode line. It can replace
;; diminish.el, delight.el, and dim.el.

;; Hide a minor mode:
;;
;;     (blackout 'auto-fill-mode)
;;
;; Change the display of a minor mode (note the leading space; this is
;; needed if you want there to be a space between this mode lighter and
;; the previous one):
;;
;;     (blackout 'auto-fill-mode " Auto-Fill")
;;
;; Change the display of a major mode:
;;
;;     (blackout 'emacs-lisp-mode "Elisp")
;;
;; Operate on a mode which hasn't yet been loaded:
;;
;;     (with-eval-after-load 'ivy
;;       (blackout 'ivy-mode))
;;
;; Usage with use-package:
;;
;;     (use-package foo
;;       :blackout t)
;;
;;     (use-package foo
;;       :blackout " Foo")
;;
;;     (use-package quux
;;       :blackout ((foo-mode . " Foo")
;;                  (bar-mode . " Bar")))

;; Please see https://github.com/raxod502/blackout for more information.

;;; Code:

(eval-when-compile
  (require 'cl-lib))

(require 'subr-x)

(defvar use-package-keywords)
(declare-function use-package-as-mode "ext:use-package-core")
(declare-function use-package-concat "ext:use-package-core")
(declare-function use-package-error "ext:use-package-core")
(declare-function use-package-process-keywords "ext:use-package-core")

(defgroup blackout nil
  "Better mode lighter overriding."
  :group 'lisp
  :link '(url-link :tag "GitHub" "https://github.com/raxod502/blackout")
  :link '(emacs-commentary-link :tag "Commentary" "blackout"))

(defcustom blackout-minor-mode-variables
  ;; Use backquote to avoid this code getting modified if someone
  ;; mutates the list.
  `((auto-fill-mode . auto-fill-function))
  "Alist of minor modes with nonstandard variable names.
\(Such minor modes are produced by passing a custom `:variable' to
`define-minor-mode'.) The keys are minor mode symbols and the
values are variable names."
  :type '(alist :key-type function :value-type variable))

(defvar blackout--mode-names nil
  "Alist mapping mode name symbols to mode line constructs, or nil.")

(defun blackout--handle-minor-mode (mode)
  "Update the name for given minor MODE in `minor-mode-alist'."
  (setq mode (alist-get mode blackout-minor-mode-variables mode))
  (when-let ((spec (assq mode minor-mode-alist)))
    (setf (nth 1 spec) (alist-get mode blackout--mode-names))))

(defun blackout--handle-major-mode ()
  "Update `mode-name' for the current buffer, if necessary."
  (when-let ((spec (assq major-mode blackout--mode-names)))
    (setq-local mode-name (cdr spec))))

;;;###autoload
(defun blackout (mode &optional replacement)
  "Do not display MODE in the mode line.
If REPLACEMENT is given, then display it instead. REPLACEMENT may
be a string or more generally any mode line construct (see
`mode-line-format')."
  (setf (alist-get mode blackout--mode-names) replacement)
  (blackout--handle-minor-mode mode)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (blackout--handle-major-mode))))

(add-hook 'after-change-major-mode-hook #'blackout--handle-major-mode)

;;;###autoload
(defun use-package-normalize/:blackout (name _keyword args)
  "Normalize the arguments to `:blackout'.
The return value is an alist whose cars are mode names and whose
cdrs are mode line constructs. For documentation on NAME,
KEYWORD, and ARGS, refer to `use-package'."
  (when (> (length args) 1)
    (use-package-error ":blackout wants at most one argument"))
  ;; If no args given, default to t.
  (let ((alist (if args (car args) t)))
    ;; Default to feature name as mode if t given.
    (when (eq alist t)
      (setq alist (use-package-as-mode name)))
    ;; If mode name given, assume we want to blacken it to nil.
    ;; Otherwise, assume we want to blacken the feature name as a mode
    ;; to the given construct.
    (cond
     ((and (symbolp alist)
           (string-suffix-p "-mode" (symbol-name alist)))
      (setq alist (cons alist nil)))
     ((or (null alist) (not (listp alist)))
      (setq alist (cons (use-package-as-mode name) alist))))
    ;; If only a cons cell given, make it into an alist.
    (unless (cl-every #'consp alist)
      (setq alist (list alist)))
    alist))

;;;###autoload
(defun use-package-handler/:blackout (name _keyword arg rest state)
  "Handle `:blackout' keyword.
For documentation on NAME, KEYWORD, ARG, REST, and STATE, refer
to `use-package'."
  (let ((body (use-package-process-keywords name rest state)))
    (use-package-concat
     body
     (mapcar
      (lambda (spec)
        `(blackout ',(car spec) ,(cdr spec)))
      arg))))

;;;###autoload
(with-eval-after-load 'use-package-core
  (when (and (boundp 'use-package-keywords)
             (listp use-package-keywords))
    (add-to-list 'use-package-keywords :blackout 'append)))

(provide 'blackout)

;; Local Variables:
;; sentence-end-double-space: nil
;; outline-regexp: ";;;;* "
;; End:

;;; blackout.el ends here
