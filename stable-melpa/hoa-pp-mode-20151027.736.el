;;; hoa-pp-mode.el --- Major mode for Hoa PP grammars -*- lexical-binding: t -*-

;; Copyright © 2015-2015, Hoa community. All rights reserved.

;; Author: Steven Rémot
;; Maintainer: Steven Rémot
;; Version: 0.3.0
;; Package-Version: 20151027.736
;; Package-Commit: 925b79930a3f4377b0fb2a36b3c6d5566d4b9a8e
;; Keywords: php, hoa
;; URL: https://github.com/hoaproject/Contributions-Emacs-Pp
;; Package-Requires: ((emacs "24.1") (names "20150723.0"))

;; This file is not part of GNU Emacs.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;     * Redistributions of source code must retain the above copyright
;;       notice, this list of conditions and the following disclaimer.
;;     * Redistributions in binary form must reproduce the above copyright
;;       notice, this list of conditions and the following disclaimer in the
;;       documentation and/or other materials provided with the distribution.
;;     * Neither the name of the Hoa nor the names of its contributors may be
;;       used to endorse or promote products derived from this software without
;;       specific prior written permission.

;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE
;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;; POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:
;;
;; This package provides a major mode for editing hoa *.pp files.
;; Its current features are:
;; - syntax coloration
;; - auto-indentation
;; - Imenu support

;;; Code:
(eval-when-compile (require 'names))

(define-namespace hoa-pp-mode-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Syntax ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst directive-regexp (rx bol "%" (group (or "token" "skip"))
                               (? (+ blank) (group (+ (not (any blank ?\n))))
                                  (? (+ blank) (group  (+ (or (not (any ?\n ?-))
                                                              (seq ?- (not (any ?> ?\n)))))))))
  "Regular expression for matching compiler directives.")

(defconst arrow-directive-regexp (rx bol "%token"
                                     (+ (or (not (any ?\n ?-))
                                            (seq ?- (not (any ?>)))))
                                     (group "->")
                                     (? (* blank) (group (+ (not (any blank ?\n)))))
                                     eol)
  "Regular expression for matching arrow clause behind comiler directives.")

(defconst rule-regexp (rx bol (? "#") (group (+ (or word (syntax symbol)))) ":" (* space) eol)
  "Regular expression for matching rule declaration.")

(defconst font-lock-keywords
  `(;; Compiler directives
    (,hoa-pp-mode-directive-regexp . (1 font-lock-keyword-face))
    (,hoa-pp-mode-directive-regexp . (2 font-lock-constant-face))
    (,hoa-pp-mode-directive-regexp . (3 font-lock-string-face))
    (,hoa-pp-mode-arrow-directive-regexp . (1 font-lock-builtin-face))
    (,hoa-pp-mode-arrow-directive-regexp . (2 font-lock-constant-face))

    ;; Rules
    (,(rx bol (* space) (? "#") (group (+ (or word (syntax symbol)))) ":" (* space) eol)  . (1 font-lock-function-name-face))

    ;; Token and rule use
    (, (rx "::" (group (+ (or word (syntax symbol)))) "::") . (1 font-lock-constant-face))
    (, (rx "<" (group (+ (or word (syntax symbol)))) ">") . (1 font-lock-constant-face))
    (, (rx bow (group (+ (or word (syntax symbol)))) "()") . (1 font-lock-function-name-face))
    )
  "Keywords highlighting for Hoa PP mode.")

(defun setup-syntax-table (&optional table)
  "Setup the syntax table for `hoa-pp-mode'.

TABLE is a syntax table.  It will be the default table if not provided."
  (modify-syntax-entry ?\" "." table)
  (modify-syntax-entry ?/ "<12" table)
  (modify-syntax-entry ?\n ">" table))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Indentation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun is-at-directive-start? ()
  "Return t if the current point is at a directive start."
  (= ?% (aref (buffer-substring-no-properties (point) (1+ (point))) 0)))

(defun is-at-rule-start? ()
  "Return t if the current point is at a rule start."
  (looking-at rule-regexp))

(defun is-in-rule? ()
  "Return t if the current point is inside a rule definition."
  (catch 'in-rule?
    (save-excursion
      (forward-line -1)
      (beginning-of-line)
      (while (not (= (point) (point-min)))
        (back-to-indentation)
        (when (is-at-directive-start?)
          (throw 'in-rule? nil))
        (when (is-at-rule-start?)
          (throw 'in-rule? t))
        (forward-line -1)
        (beginning-of-line)))))

(defun ensure-in-text ()
  "Go back to indentation of point is before line's text."
  (let ((text-start (save-excursion
                      (back-to-indentation)
                      (point))))
    (when (< (point) text-start)
      (back-to-indentation))))

(defun indent-line ()
  "Indent the current line."
  (interactive)
  (save-excursion
    (back-to-indentation)
    (cond
     ((is-at-directive-start?)
      (beginning-of-line)
      (just-one-space 0))
     ((is-at-rule-start?)
      (beginning-of-line)
      (just-one-space 0))
     ((is-in-rule?)
      (indent-to (indent-next-tab-stop 0)))
     (t
      (indent-to 0))))
  (ensure-in-text))

(defun setup-indentation ()
  "Setup the indent function for `hoa-pp-mode'."
  (set (make-local-variable 'indent-line-function) #'indent-line)
  (set (make-local-variable 'electric-indent-chars) '(?\n ?:)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Imenu ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst imenu-expressions (list
                             (list "Tokens" (rx bol "%token" (+ blank) (group (+ (not (any blank ?\n))))) 1)
                             (list "Rules" rule-regexp 1))
  "Imenu configuration for `hoa-pp-mode'.")

(defun setup-imenu ()
  "Configure Imenu for `hoa-pp-mode'.

Provide menu section for tokens and rules."
  (setq imenu-generic-expression imenu-expressions)
  (imenu-add-menubar-index))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mode definition ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;###autoload
(define-derived-mode hoa-pp-mode
  prog-mode "Hoa PP"
  "Major mode for editing Hoa PP grammars.
\\{hoa-pp-mode-map"
  (set (make-local-variable 'font-lock-defaults) '(hoa-pp-mode-font-lock-keywords))
  (hoa-pp-mode-setup-syntax-table)
  (hoa-pp-mode-setup-indentation)
  (hoa-pp-mode-setup-imenu))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pp$" . hoa-pp-mode))

(provide 'hoa-pp-mode)

;;; hoa-pp-mode.el ends here
