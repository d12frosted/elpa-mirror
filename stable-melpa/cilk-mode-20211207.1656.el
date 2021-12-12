;;; cilk-mode.el --- Minor mode for Cilk code editing -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Supertech Research Group, CSAIL, MIT
;;
;; Author: Alexandros-Stavros Iliopoulos <https://github.com/ailiop>
;; Maintainer: Alexandros-Stavros Iliopoulos <1577182+ailiop@users.noreply.github.com>
;; Created: November 30, 2021
;; Modified: December 7, 2021
;; Version: 0.1.1
;; Package-Version: 20211207.1656
;; Package-Commit: 51eb3088337674389275b9352a1b16dce2d917db
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
;; Each of the above features is automatically enabled/disabled via the
;; following hook functions for `cilk-mode'.  In fact, activating `cilk-mode'
;; does nothing except trigger the functions in `cilk-mode-hook'.  To disable
;; any feature hook function `cilk-mode-<feature>', set the value of the
;; corresponding variable `cilk-mode-enable-<feature>' to `nil' BEFORE loading
;; the package.
;;
;; Each of the hook functions above can also be called interactively (in any
;; mode) to toggle the corresponding feature on/off.
;;
;; The `cilk-mode' minor mode can only be enabled in buffers with major mode
;; `c-mode' or `c++-mode' (provided by `cc-mode').
;;
;;; Code:


(require 'cc-mode)  ; `cilk-mode' is only applicable over `c-mode'/`c++-mode'



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
  "Path to the OpenCilk compiler clang executable.

This is used as the syntax checker for flycheck."
  :type '(file :must-match t))


(defcustom cilk-mode-opencilk-cilk-flags '("-fopencilk")
  "OpenCilk compiler flags for building Cilk code.

To change non-Cilk-specific arguments to the OpenCilk compiler
for use with flycheck, use `flycheck-clang-args'."
  :type '(repeat string))



;; ==================================================
;;; CC MODE KEYWORD LIST AMENDMENT FOR CILK
;; ==================================================

(defcustom cilk-mode-enable-cc-keywords t
  "If non-nil, register Cilk keywords with CC Mode keyword regexps.

This variable is only checked when the cilk-mode.el package is
loaded, to control whether to add `cilk-mode-cc-keywords' to
`cilk-mode-hook'."
  :type 'boolean)


;; only required at compile time to get the CC Mode C/C++ language constants
(when cilk-mode-enable-cc-keywords
  (eval-when-compile (require 'cc-langs)))


(defvar cilk-mode--cc-keywords-flag) ; current state: t=on, nil=off

(defun cilk-mode-cc-keywords (&optional arg)
  "Toggle Cilk keyword indentation via CC Mode keyword regexps.

Cilk keyword indentation is enabled by changing the following CC
Mode regexp variables for `c-mode' and `c++-mode':

o `c-block-stmt-1-key' ==> also keywords in `cilk-mode--block-stmt-1-kwds'
o `c-block-stmt-2-key' ==> also keywords in `cilk-mode--block-stmt-2-kwds'
o `c-opt-block-stmt-key' ==> (update based on the 2 variables above)
o `c-simple-stmt-key' ==> also keywords in `cilk-mode-simple-stmt-kwds'

If called interactively, enable Cilk keyword indentation with CC
Mode if prefix argument ARG is positive, and disable it if ARG is
zero or negative; if no prefix argument is given, toggle Cilk
keyword indentation.  If called from Lisp, also enable Cilk
keyword indentation if ARG is omitted or nil, and toggle it if
ARG is `toggle'; disable it otherwise.

This function should only be called from buffers where the major
mode is `c-mode' or `c++-mode'."
  (interactive "p")
  (when (and (called-interactively-p 'any) (not arg))
    (setq arg 'toggle))
  (when (eq arg 'toggle)
    (cilk-mode-cc-keywords cilk-mode--cc-keywords-flag))
  (when (xor cilk-mode--cc-keywords-flag (not arg)) ; if actually toggling
    (setq cilk-mode--cc-keywords-flag (not arg))
    (setq c-block-stmt-1-key
          (c-make-keywords-re t
            (append (c-lang-const c-block-stmt-1-kwds)
                    (unless arg cilk-mode--block-stmt-1-kwds))))
    (setq c-block-stmt-2-key
          (c-make-keywords-re t
            (append (c-lang-const c-block-stmt-2-kwds)
                    (unless arg cilk-mode--block-stmt-2-kwds))))
    (setq c-opt-block-stmt-key
          (c-make-keywords-re t
            (append (c-lang-const c-block-stmt-1-kwds)
                    (c-lang-const c-block-stmt-2-kwds)
                    (unless arg (append cilk-mode--block-stmt-1-kwds
                                        cilk-mode--block-stmt-2-kwds)))))
    (setq c-simple-stmt-key
          (c-make-keywords-re t
            (append (c-lang-const c-simple-stmt-kwds)
                    (unless arg cilk-mode--simple-stmt-kwds))))))



;; ==================================================
;;; FONT LOCKING OF CILK PARALLEL KEYWORDS
;; ==================================================

(defcustom cilk-mode-enable-font-lock (require 'font-lock nil 'noerror)
  "If non-nil, enable automatic Cilk keyword font-locking.

This variable is only checked when the cilk-mode.el package is
loaded, to control whether to add `cilk-mode-font-lock' to
`cilk-mode-hook'."
  :type 'boolean)


;; in case `cilk-mode-enable-font-lock' was pre-set to non-nil value
(when cilk-mode-enable-font-lock (require 'font-lock))


(defface cilk-mode-parallel-keyword
  `((t :inherit 'font-lock-keyword-face))
  "Cilk mode face used to highlight parallel Cilk keywords."
  :group 'cilk)


(defconst cilk-mode--cilk-keywords-regexp
  (regexp-opt cilk-mode--all-kwds 'symbols)
  "Optimized regexp for matching Cilk keyword symbols.")


(defvar cilk-mode--font-lock-flag) ; current state: t=on, nil=off

(defun cilk-mode-font-lock (&optional arg)
  "Toggle Cilk keyword fontification in current buffer.

Cilk keywords are fontified by applying the
`cilk-mode-parallel-keyword' face to all Cilk keywords.
Recognized Cilk keywords can be seen in `cilk-mode--all-kwds'.

If called interactively, enable Cilk keyword fontification with
if prefix argument ARG is positive, and disable it if ARG is zero
or negative; if no prefix argument is given, toggle Cilk keyword
fontification.  If called from Lisp, also enable Cilk keyword
fontification if ARG is omitted or nil, and toggle it if ARG is
`toggle'; disable it otherwise."
  (interactive "p")
  (when (and (called-interactively-p 'any) (not arg))
    (setq arg 'toggle))
  (when (eq arg 'toggle)
    (cilk-mode-font-lock cilk-mode--font-lock-flag))
  (when (xor cilk-mode--font-lock-flag (not arg)) ; if actually toggling
    (setq cilk-mode--font-lock-flag (not arg))
    ;; add/remove custom face to/from Cilk keywords
    ;; (NOTE: Use `font-lock-add-keywords' and `font-lock-remove-keywords'
    ;; instead of the fontification mechanisms in `cc-mode', because the
    ;; latter would seem to require copying an entire matcher like
    ;; `c-cpp-matchers'.)
    (let ((font-lock-cilk-keywords-list
           `((,cilk-mode--cilk-keywords-regexp . 'cilk-mode-parallel-keyword))))
      (funcall (if cilk-mode--font-lock-flag
                   #'font-lock-add-keywords
                 #'font-lock-remove-keywords)
               nil font-lock-cilk-keywords-list))
    (font-lock-flush)))



;; ==================================================
;;; FLYCHECK SYNTAX CHECKING
;; ==================================================

(defcustom cilk-mode-enable-flycheck-opencilk (require 'flycheck nil 'noerror)
  "If non-nil, enable Cilk syntax checking with `flycheck'.

This variable is only checked when the cilk-mode.el package is
loaded, to control whether to add `cilk-mode-flycheck-opencilk'
to `cilk-mode-hook'."
  :type 'boolean)


;; in case `cilk-mode-enable-flycheck-opencilk' was pre-set to non-nil value
(when cilk-mode-enable-flycheck-opencilk (require 'flycheck))


(when (require 'flycheck nil 'noerror)


  (defvar flycheck-c/c++-clang-executable)
  (defvar flycheck-clang-args)
  (defvar flycheck-checker)
  (declare-function flycheck-buffer "flycheck.el" nil)


  (defvar cilk-mode--flycheck-opencilk-flag) ; current state: t=on, nil=off
  (declare-function cilk-mode-flycheck-opencilk "cilk-mode.el")

  (defun cilk-mode-flycheck-opencilk (&optional arg)
    "Toggle Cilk options for the `c/c++-clang' `flycheck' checker'.

Cilk C/C++ syntax checking with `flycheck-mode' in the current
buffer is enabled by setting the buffer-local value of
`flycheck-checker' to `c/c++-clang', and also creating
buffer-local bindings for the following `flycheck' variables,
using the values of the corresponding `cilk-mode' constants:

o `flycheck-c/c++-clang-executable'  = `cilk-mode-flycheck-opencilk-executable'
o `flycheck-clang-args'             += `cilk-mode-opencilk-cilk-flags'

If called interactively, enable Cilk syntax checking in
`flycheck-mode' if prefix argument ARG is positive, and disable
it if ARG is zero or negative; if no prefix argument is given,
toggle Cilk syntax checking.  If called from Lisp, also enable
Cilk syntax checking if ARG is omitted or nil, and toggle it if
ARG is `toggle'; disable it otherwise."
    (interactive "p")
    (when (and (called-interactively-p 'any) (not arg))
      (setq arg 'toggle))
    (when (eq arg 'toggle)
      (cilk-mode-flycheck-opencilk cilk-mode--flycheck-opencilk-flag))
    (when (xor cilk-mode--flycheck-opencilk-flag (not arg)) ; if actually toggling
      (setq cilk-mode--flycheck-opencilk-flag (not arg))
      (if cilk-mode--flycheck-opencilk-flag
          (progn
            (setq-local flycheck-c/c++-clang-executable
                        cilk-mode-opencilk-executable)
            (setq-local flycheck-clang-args
                        (append flycheck-clang-args
                                cilk-mode-opencilk-cilk-flags))
            (setq-local flycheck-checker 'c/c++-clang))
        (kill-local-variable 'flycheck-c/c++-clang-executable)
        (kill-local-variable 'flycheck-clang-args)
        (kill-local-variable 'flycheck-checker))
      (when (bound-and-true-p flycheck-mode)
        (flycheck-buffer)))))



;; ==================================================
;;; CILK MODE
;; ==================================================

;;;###autoload
(define-minor-mode cilk-mode
  "Minor mode for editing Cilk source code.

Can only be enabled in buffers where `major-mode' is either
`c-mode' or `c++-mode' (derived from CC Mode).

The `cilk-mode' minor mode by itself does nothing but provide a
way to run Cilk-specific functions via `cilk-mode-hook'.  When
loading the `cilk-mode' package, the following functions are
added to `cilk-mode-hook' if the corresponding flag variables are
set to non-nil at package initialization time:

1. `cilk-mode-cc-keywords'       (flag: `cilk-mode-enable-cc-keywords')
2. `cilk-mode-font-lock'         (flag: `cilk-mode-enable-font-lock')
3. `cilk-mode-flycheck-opencilk' (flag: `cilk-mode-enable-flycheck-opencilk')"
  :lighter " Cilk"
  (when (and (bound-and-true-p c-buffer-is-cc-mode)
             (member major-mode '('c-mode 'c++-mode)))
    (error "Unsupported major mode `%s' for minor mode `cilk-mode'" major-mode))
  ;; initialize buffer-local feature-specific state flags to track toggling
  (setq-local cilk-mode--cc-keywords-flag nil)
  (setq-local cilk-mode--font-lock-flag nil)
  (when (fboundp 'cilk-mode-flycheck-opencilk)
    (setq-local cilk-mode--flycheck-opencilk-flag nil)))


(when cilk-mode-enable-cc-keywords
  (add-hook 'cilk-mode-hook
            (lambda () (cilk-mode-cc-keywords (not cilk-mode)))))

(when cilk-mode-enable-font-lock
  (add-hook 'cilk-mode-hook
            (lambda () (cilk-mode-font-lock (not cilk-mode)))))

(when (and cilk-mode-enable-flycheck-opencilk
           (fboundp 'cilk-mode-flycheck-opencilk))
  (add-hook 'cilk-mode-hook
            (lambda () (cilk-mode-flycheck-opencilk (not cilk-mode)))))


(provide 'cilk-mode)

;;; cilk-mode.el ends here
