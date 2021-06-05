;;; lisp-local.el --- Allow different Lisp indentation in each buffer -*- lexical-binding: t -*-
;;
;; Copyright 2020 Lassi Kortela
;; SPDX-License-Identifier: ISC
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lispunion/emacs-lisp-local
;; Package-Commit: 22e221c9330d2b5dc07e8b2caa34c83ac7c20b0d
;; Package-Requires: ((emacs "24.3"))
;; Package-Version: 20210605.1347
;; Package-X-Original-Version: 0.1.0
;; Keywords: languages lisp
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Languages in the Lisp family have macros, which means that some
;; Lisp forms sometimes need custom indentation.  Emacs enables this
;; via symbol properties: e.g. (put 'when 'lisp-indent-function 1)
;;
;; Unfortunately symbol properties are global to all of Emacs.  That
;; makes it impossible to have different Lisp indentation settings in
;; different buffers.  This package works around the problem by adding
;; a `lisp-indent-function' wrapper that temporarily swaps the global
;; properties for buffer-local values whenever you indent some code.
;; It then changes them back to their global values after indenting.
;;
;; The buffer-local variable `lisp-local-indent' controls indentation.
;; When a particular Lisp form is not mentioned in that variable, the
;; global indentation settings are used as a fallback.
;;
;; Enable via one or more of the following hooks:
;;
;; (add-hook 'emacs-lisp-mode-hook 'lisp-local)
;; (add-hook 'lisp-mode-hook       'lisp-local)
;; (add-hook 'scheme-mode-hook     'lisp-local)
;; (add-hook 'clojure-mode-hook    'lisp-local)
;;
;; This package does not say where your indentation settings should
;; come from.  Currently you can set them in `.dir-locals.el' or a
;; custom hook function.  In the future, more convenient ways will
;; hopefully be provided by other packages.
;;
;;; Code:

(require 'cl-lib)

(defvar-local lisp-local-indent nil
  "Lisp indentation properties for this buffer.

This is a (SYMBOL INDENT SYMBOL INDENT ...) property list.
Example: (if 1 let1 2 with-input-from-string 1)")

(defvar-local lisp-local--state nil
  "Internal state of `lisp-local' for this buffer.")

(defvar lisp-local--indenting-p nil
  "Internal variable to prevent loops.")

(defun lisp-local--valid-plist-p (plist &optional valid-value-p)
  "Return t if PLIST is a valid property list, nil otherwise.

Optional argument VALID-VALUE-P is a function to validate each
value in the property list.  Keys must always be symbols."
  (and (listp plist)
       (not (null (cl-list-length plist)))
       (progn (while (and (consp plist)
                          (symbolp (car plist))
                          (consp (cdr plist))
                          (or (null valid-value-p)
                              (funcall valid-value-p (cadr plist))))
                (setq plist (cddr plist)))
              (null plist))))

(defun lisp-local--make-plists (settings propnames)
  "Internal helper to merge SETTINGS and PROPNAMES into PLISTS."
  (let (props)
    (while settings
      (let ((symbol (nth 0 settings))
            (indent (nth 1 settings)))
        (setq settings (nthcdr 2 settings))
        (push (cons symbol
                    (cl-mapcan (lambda (prop) (list prop indent))
                               propnames))
              props)))
    props))

(defun lisp-local--call-with-properties (fun &rest args)
  "Apply FUN to ARGS with local values for symbol properties."
  (cl-assert (consp lisp-local--state))
  (cond ((not (lisp-local--valid-plist-p lisp-local-indent))
         (message "Warning: ignoring invalid lisp-local-indent")
         (apply fun args))
        (t
         (let* ((new-plists
                 (lisp-local--make-plists
                  lisp-local-indent (cdr lisp-local--state)))
                (old-plists
                 (mapcar (lambda (sym) (cons sym (symbol-plist sym)))
                         (mapcar #'car new-plists))))
           (unwind-protect
               (progn (mapc (lambda (sym-plist)
                              (setplist (car sym-plist) (cdr sym-plist)))
                            new-plists)
                      (apply fun args))
             (mapc (lambda (sym-plist)
                     (setplist (car sym-plist) (cdr sym-plist)))
                   old-plists))))))

(defun lisp-local--indent-function (&rest args)
  "Local-properties wrapper for use as variable `lisp-indent-function'.

Applies the old function from the variable `lisp-indent-function'
to ARGS."
  (cl-assert (consp lisp-local--state))
  (unless lisp-local--indenting-p
    (let ((lisp-local--indenting-p t))
      (apply #'lisp-local--call-with-properties
             (car lisp-local--state)
             args))))

(defun lisp-local--indent-properties ()
  "Internal helper for `lisp-local'."
  (cond ((derived-mode-p 'clojure-mode)
         '(lisp-indent-function clojure-indent-function))
        ((derived-mode-p 'emacs-lisp-mode)
         '(lisp-indent-function emacs-lisp-indent-function))
        ((derived-mode-p 'lisp-mode)
         '(lisp-indent-function common-lisp-indent-function))
        ((derived-mode-p 'scheme-mode)
         '(lisp-indent-function scheme-indent-function))))

(defun lisp-local--valid-indent-amount-p (indent)
  "Return t if INDENT is a valid indent amount, nil otherwise."
  (and (integerp indent) (>= indent 0)))

(defun lisp-local--valid-indent-settings-p (indent)
  "Return t if INDENT is a valid value for `lisp-local-indent'."
  (lisp-local--valid-plist-p indent #'lisp-local--valid-indent-amount-p))

;;;###autoload
(defun lisp-local-set-indent (symbol indent)
  "Set Lisp indentation of SYMBOL to INDENT for the current buffer only.

This is a convenience function to change the `lisp-local-indent'
variable from other Emacs packages."
  (cl-assert (symbolp symbol))
  (cl-assert (lisp-local--valid-indent-amount-p indent))
  (setq lisp-local-indent
        (plist-put lisp-local-indent symbol indent))
  t)

;;;###autoload
(defun lisp-local ()
  "Respect local Lisp indentation settings in the current buffer.

Causes the settings in the variable `lisp-local-indent' to take
effect for the current buffer.  The effect lasts until the buffer
is killed or the major mode is changed.

This is meant to be used from one or more of the following hooks:

    (add-hook 'emacs-lisp-mode-hook 'lisp-local)
    (add-hook 'lisp-mode-hook       'lisp-local)
    (add-hook 'scheme-mode-hook     'lisp-local)
    (add-hook 'clojure-mode-hook    'lisp-local)

`lisp-local' signals an error if the current major mode is not a
Lisp-like mode known to it.  It does no harm to call it more than
once.

Implementation note: `lisp-local' achieves its effect by
overriding the variable `lisp-indent-function' with its own
function wrapping the real indent function provided by the major
mode.  The wrapper overrides global indentation-related symbol
properties with their local values, then restores them back to
their global values."
  (let ((old-indent (or (and (consp lisp-local--state)
                             (car lisp-local--state))
                        lisp-indent-function))
        (properties
         (or (lisp-local--indent-properties)
             (error "The lisp-local package does not work with %S"
                    major-mode))))
    (setq-local lisp-local--state
                (cons (if (or (eq old-indent 'lisp-local--indent-function)
                              (eq old-indent (function
                                              lisp-local--indent-function)))
                          'lisp-indent-function
                        lisp-indent-function)
                      properties)))
  (setq-local lisp-indent-function
              #'lisp-local--indent-function)
  t)

(put 'lisp-local-indent 'safe-local-variable
     'lisp-local--valid-indent-settings-p)

(provide 'lisp-local)

;;; lisp-local.el ends here
