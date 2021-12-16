;;; cilk-mode.el --- Minor mode for Cilk code editing -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Supertech Research Group, CSAIL, MIT
;;
;; Author: Alexandros-Stavros Iliopoulos <https://github.com/ailiop>
;; Maintainer: Alexandros-Stavros Iliopoulos <1577182+ailiop@users.noreply.github.com>
;; Created: November 30, 2021
;; Modified: December 15, 2021
;; Version: 0.2.0
;; Package-Version: 20211215.1805
;; Package-Commit: af454e347ece6c300fef266048f5c906792ec934
;; Keywords: c convenience faces languages
;; Homepage: https://github.com/ailiop/cilk-mode
;; Package-Requires: ((emacs "25.1") (flycheck "32-cvs"))
;;
;; This file is not part of GNU Emacs.
;;

;;; License:
;;
;;  MIT License
;;
;;  Permission is hereby granted, free of charge, to any person obtaining a copy
;;  of this software and associated documentation files (the "Software"), to
;;  deal in the Software without restriction, including without limitation the
;;  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
;;  sell copies of the Software, and to permit persons to whom the Software is
;;  furnished to do so, subject to the following conditions:
;;
;;  The above copyright notice and this permission notice shall be included in
;;  all copies or substantial portions of the Software.
;;
;;  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;;  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
;;  IN THE SOFTWARE.
;;

;;; Commentary:
;;
;; Provides `cilk-mode', a minor mode that augments `c-mode' and `c++-mode'
;; for editing Cilk source code.
;;
;; This package simply groups together a few small customizations of other
;; modes to make Cilk C/C++ code editing more convenient.  Specifically, the
;; package provides the following functions:
;;
;; 1. `cilk-mode-cc-keywords' :: Correct indentation of code blocks with Cilk
;; keywords in CC Mode.  This is done by modifying buffer-local bindings of
;; the relevant C/C++ keyword regexp variables of `cc-mode'.
;;
;; 2. `cilk-mode-font-lock' :: Fontification of Cilk keywords.  This is done
;; via `font-lock-mode' and the provided face `cilk-mode-parallel-keyword'.
;; By default, the `cilk-mode-parallel-keyword' face is the same as
;; `font-lock-keyword-face'.  To change how Cilk keywords are fontified, use
;; the `set-face-attribute' function to customize the
;; `cilk-mode-parallel-keyword' face.
;;
;; 3. `cilk-mode-flycheck-opencilk' :: Syntax checking with `flycheck' and the
;; OpenCilk compiler (https://opencilk.org).  This is done via buffer-local
;; bindings of `flycheck' options for the `c/c++-clang' checker.  If
;; `flycheck' is not installed, this feature is elided.  The OpenCilk compiler
;; path is found in `cilk-mode-flycheck-opencilk-executable'.
;;
;; Each of the above features is enabled whenever the `cilk-mode' minor mode
;; is activated.  To stop a feature with function `cilk-mode-<feature>' from
;; automatically activating with `cilk-mode', set the corresponding variable
;; `cilk-mode-enable-<feature>' to nil.  To toggle a feature on or off, one
;; may also call the corresponding function interactively.
;;
;; The `cilk-mode' minor mode can only be enabled in buffers with major mode
;; `c-mode' or `c++-mode' (provided by CC Mode).
;;

;;; Code:


(require 'cc-mode)
(eval-when-compile
  (require 'cc-langs))

(require 'font-lock)



;; ==================================================
;;; PARAMETERS
;; ==================================================

(defgroup cilk nil
  "Customization group for `cilk-mode' options."
  :group 'c)


;; ---------- Cilk keywords

(defconst cilk-mode--block-stmt-1-kwds '("cilk_scope" "cilk_spawn")
  "Cilk keywords followed directly by a substatement.")

(defconst cilk-mode--block-stmt-2-kwds '("cilk_for")
  "Cilk keywords followed by a paren sexp and then by a substatment.")

(defconst cilk-mode--simple-stmt-kwds '("cilk_sync")
  "Cilk keywords followed by nothing.")

(defconst cilk-mode--all-kwds (append cilk-mode--block-stmt-1-kwds
                                      cilk-mode--block-stmt-2-kwds
                                      cilk-mode--simple-stmt-kwds)
  "All Cilk keywords.")


;; ---------- OpenCilk

(defcustom cilk-mode-opencilk-executable "/opt/opencilk/bin/clang"
  "Path to the OpenCilk compiler executable.

This is used as the syntax checker for flycheck."
  :type '(file :must-match t))


(defcustom cilk-mode-opencilk-cilk-flags '("-fopencilk")
  "OpenCilk compiler flags for building Cilk code.

To change non-Cilk-specific arguments to the OpenCilk compiler
for use with flycheck, use `flycheck-clang-args'."
  :type '(repeat string))



;; ==================================================
;;; "TOGGLEABLE" FEATURE DEFUN MACRO
;; ==================================================

(defmacro cilk-mode-defun-toggleable (name doc &rest body)
  "Define a feature NAME which can be set or toggled.

Specifically, define the following, using NAME to generate
appropriate symbols:

1. A buffer-local variable named `cilk-mode--NAME-flag', which
   tracks the current state of the feature (t=on, nil=off).

2. An interactive function named `cilk-mode-NAME' with a single
   optional argument to set or toggle the feature.

The expanded feature function definition roughly looks like the
following:

\(defun cilk-mode-NAME (&optional arg)
  DOC ; with added paragraph about arg and toggling
  (interactive \"P\")
  (...) ;; set feature-state flag according to arg
  BODY)

When evaluating the feature function, the corresponding state
flag is set to t or nil to indicate that the feature should be
enabled or disabled, respectively.  This is done before
evaluating the BODY, which can refer to the value of
`cilk-mode--NAME-flag' to handle feature activation and
deactivation.

The BODY should *not* change the value of `cilk-mode--NAME-flag'.

If a call to `cilk-mode-NAME' does not change the feature state,
then the BODY is not evaluated.  That is, the feature function
will be idempotent even if the BODY is not."
  (declare (doc-string 2)
           (indent defun))
  (let ((func-name
         (intern (concat "cilk-mode-" (symbol-name name))))
        (feature-flag
         (intern (concat "cilk-mode--" (symbol-name name) "-flag"))))
    `(progn
       ;; buffer-local state variable
       (defvar-local ,feature-flag nil
         ,(concat "Current state of `"
                  (symbol-name func-name)
                  "': t=on, nil=off."))
       ;; toggle-able feature defun
       (defun ,func-name (&optional arg)
         ,(concat doc "

If called interactively, enable this feture if prefix ARG is
positive, and disable it if ARG is zero or negative; if no prefix
ARG is given, toggle this feature.  If called from Lisp, also
enable this feature if ARG is omitted or nil, and toggle it if
ARG is `toggle'; disable it otherwise.")
         (interactive "P")
         ;; canonicalize input arg: enable=nil, disable=t
         (cond ((numberp arg)
                (setq arg (<= arg 0)))
               ((or (eq arg 'toggle)
                    (and (called-interactively-p 'any) (not arg)))
                (setq arg ,feature-flag)))
         ;; run BODY only if actually changing the feature state
         (when (xor ,feature-flag (not arg))
           (setq ,feature-flag (not arg))
           ,@body)))))



;; ==================================================
;;; CC MODE KEYWORD LIST AMENDMENT FOR CILK
;; ==================================================

(defcustom cilk-mode-enable-cc-keywords t
  "If non-nil, enable Cilk keyword indentation when activating `cilk-mode'."
  :type 'boolean)


(cilk-mode-defun-toggleable cc-keywords
  "Toggle Cilk keyword indentation via CC Mode keyword regexps.

Cilk keyword indentation is enabled by changing the following CC
Mode regexp variables for `c-mode' and `c++-mode':

o `c-block-stmt-1-key' ==> also keywords in `cilk-mode--block-stmt-1-kwds'
o `c-block-stmt-2-key' ==> also keywords in `cilk-mode--block-stmt-2-kwds'
o `c-opt-block-stmt-key' ==> (update based on the 2 variables above)
o `c-simple-stmt-key' ==> also keywords in `cilk-mode--simple-stmt-kwds'

This function should only be called from buffers where the major
mode is `c-mode' or `c++-mode'."
  (setq c-block-stmt-1-key
        (c-make-keywords-re t
          (append (c-lang-const c-block-stmt-1-kwds)
                  (if cilk-mode--cc-keywords-flag
                      cilk-mode--block-stmt-1-kwds))))
  (setq c-block-stmt-2-key
        (c-make-keywords-re t
          (append (c-lang-const c-block-stmt-2-kwds)
                  (if cilk-mode--cc-keywords-flag
                      cilk-mode--block-stmt-2-kwds))))
  (setq c-opt-block-stmt-key
        (c-make-keywords-re t
          (append (c-lang-const c-block-stmt-1-kwds)
                  (c-lang-const c-block-stmt-2-kwds)
                  (if cilk-mode--cc-keywords-flag
                      (append cilk-mode--block-stmt-1-kwds
                              cilk-mode--block-stmt-2-kwds)))))
  (setq c-simple-stmt-key
        (c-make-keywords-re t
          (append (c-lang-const c-simple-stmt-kwds)
                  (if cilk-mode--cc-keywords-flag
                      cilk-mode--simple-stmt-kwds)))))



;; ==================================================
;;; FONT LOCKING OF CILK PARALLEL KEYWORDS
;; ==================================================

(defcustom cilk-mode-enable-font-lock t
  "If non-nil, enable Cilk keyword font-locking when activating `cilk-mode'."
  :type 'boolean)


(defface cilk-mode-parallel-keyword
  `((t :inherit 'font-lock-keyword-face))
  "Cilk mode face used to highlight parallel Cilk keywords."
  :group 'cilk)


(defconst cilk-mode--cilk-keywords-regexp
  (regexp-opt cilk-mode--all-kwds 'symbols)
  "Optimized regexp for matching Cilk keyword symbols.")


(cilk-mode-defun-toggleable font-lock
  "Toggle Cilk keyword fontification in current buffer.

Cilk keywords are fontified by applying the
`cilk-mode-parallel-keyword' face to all Cilk keywords.
Recognized Cilk keywords can be seen in `cilk-mode--all-kwds'."
  (let ((font-lock-cilk-keywords-list
         `((,cilk-mode--cilk-keywords-regexp . 'cilk-mode-parallel-keyword))))
    ;; NOTE: Use `font-lock-add-keywords' and `font-lock-remove-keywords'
    ;; instead of the fontification mechanisms in `cc-mode', because the latter
    ;; would seem to require copying an entire matcher like `c-cpp-matchers'.
    (funcall (if cilk-mode--font-lock-flag
                 #'font-lock-add-keywords
               #'font-lock-remove-keywords)
             nil font-lock-cilk-keywords-list))
  (font-lock-flush))



;; ==================================================
;;; FLYCHECK SYNTAX CHECKING
;; ==================================================

(defcustom cilk-mode-enable-flycheck-opencilk (require 'flycheck nil 'noerror)
  "If non-nil, enable Cilk checking with `flycheck' when activating `cilk-mode'."
  :type 'boolean)


(when (require 'flycheck nil 'noerror)


  (defvar-local cilk-mode--flycheck-checker-prev nil
    "Value of `flycheck-checker' before enabling `cilk-mode-flycheck-opencilk'.")


  (defvar flycheck-c/c++-clang-executable)
  (defvar flycheck-clang-args)
  (defvar flycheck-checker)
  (declare-function flycheck-buffer "flycheck.el" nil)


  (declare-function cilk-mode-flycheck-opencilk "cilk-mode.el")

  (cilk-mode-defun-toggleable flycheck-opencilk
    "Toggle Cilk options for the `c/c++-clang' flycheck checker'.

Cilk C/C++ syntax checking with `flycheck-mode' in the current
buffer is enabled by setting the buffer-local value of
`flycheck-checker' to `c/c++-clang', and also creating
buffer-local bindings for the following `flycheck' variables,
using the values of the corresponding `cilk-mode' constants:

o `flycheck-c/c++-clang-executable'  = `cilk-mode-flycheck-opencilk-executable'
o `flycheck-clang-args'             += `cilk-mode-opencilk-cilk-flags'

Disabling this feature resets `flycheck-checker' to its
buffer-local value at the time when the feature was enabled; it
also deletes the above local bindings."
    (if cilk-mode--flycheck-opencilk-flag
        (progn
          (setq-local flycheck-c/c++-clang-executable
                      cilk-mode-opencilk-executable)
          (setq-local flycheck-clang-args
                      (append flycheck-clang-args
                              cilk-mode-opencilk-cilk-flags))
          (setq cilk-mode--flycheck-checker-prev flycheck-checker)
          (setq flycheck-checker 'c/c++-clang))
      (kill-local-variable 'flycheck-c/c++-clang-executable)
      (kill-local-variable 'flycheck-clang-args)
      (setq flycheck-checker cilk-mode--flycheck-checker-prev))
    (when (bound-and-true-p flycheck-mode)
      (flycheck-buffer))))



;; ==================================================
;;; CILK MODE
;; ==================================================

;;;###autoload
(define-minor-mode cilk-mode
  "Minor mode for editing Cilk source code.

Can only be enabled in buffers where `major-mode' is either
`c-mode' or `c++-mode' (derived from CC Mode).

Activating the `cilk-mode' minor mode activates all features for
which the corresponding flag (see below) is non-nil.
Deactivating the `cilk-mode' minor mode deactivates all features
unconditionally.

1. `cilk-mode-cc-keywords'       (flag: `cilk-mode-enable-cc-keywords')
2. `cilk-mode-font-lock'         (flag: `cilk-mode-enable-font-lock')
3. `cilk-mode-flycheck-opencilk' (flag: `cilk-mode-enable-flycheck-opencilk')"
  :lighter " Cilk"
  (when (and (bound-and-true-p c-buffer-is-cc-mode)
             (member major-mode '('c-mode 'c++-mode)))
    (error "Unsupported major mode `%s' for minor mode `cilk-mode'" major-mode))
  (if cilk-mode
      (progn
        (when cilk-mode-enable-cc-keywords
          (cilk-mode-cc-keywords +1))
        (when cilk-mode-enable-font-lock
          (cilk-mode-font-lock +1))
        (when (and cilk-mode-enable-flycheck-opencilk
                   (fboundp 'cilk-mode-flycheck-opencilk))
          (cilk-mode-flycheck-opencilk +1)))
    (cilk-mode-cc-keywords -1)
    (cilk-mode-font-lock -1)
    (when (fboundp' cilk-mode-flycheck-opencilk)
      (cilk-mode-flycheck-opencilk -1))))


(provide 'cilk-mode)

;;; cilk-mode.el ends here
