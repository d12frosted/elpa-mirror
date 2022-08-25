;;; roy-mode.el --- Roy major mode

;; Version: 0.1.0
;; Package-Version: 20121208.1158
;; Package-Commit: e1a4fb5ec0f46e82f569865ca47042ba5934e425
;; URL: https://github.com/folone/roy-mode

;; Copyright (C) 2011  Free Software Foundation, Inc.

;; Author: Georgii Leontiev
;; Keywords: extensions

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;; This mode is based on generic mode
;; (http://www.emacswiki.org/emacs/GenericMode),
;; therefore, it is required.
;;

;;; Code:
(require 'generic-x)

(defvar roy-keywords
  '("with" "macro" "return" "bind" "do" "case" "match"
    "type" "data" "else" "then" "if" "fn" "let" "true" "false")
  "Roy keywords.")

;;
;; Syntax highligh
;;

;;;###autoload
(define-generic-mode 'roy-mode
  '("//[^\r\n]*\n") ;; comments
  roy-keywords
  '(;; fixnums
    ("[0-9]+" . 'font-lock-variable-name-face)
    ;; floats
    ("[0-9]+\.[0-9]+" . 'font-lock-variable-name-face)
    ;; types
    ("\\(^\\|[^_]\\)\\b\\([A-Z]+\\(\\w\\|_\\)*\\)" . 'font-lock-type-face)
    ;; opareators and constants
    ("\\([!-+*/~⊥πτ:≠λ←→⇒∈∉∘<>=&!?%^]+\\)" 1 'font-lock-function-name-face)
    ;; functions
    ("^\\s *let\\s +\\([^( \t\n]+\\)" 1 'font-lock-function-name-face)
    ("\\<\\(e\\(?:mpty\\|ven\\)\\|f\\(?:ilter\\|lip\\|oldl\\)\\|head\\|id\\|l\\(?:ength\\|og\\)\\|ma\\(?:p\\|ybe\\)\\|not\\|odd\\|pred\\|replicate\\|succ\\|ta\\(?:il\\|ke\\)\\)\\>" 1 'font-lock-function-name-face)
    )
  '("\\.roy$")                      ;; files for which to activate this mode
  nil                               ;; other functions to call
  "A simple mode for roy files"     ;; doc string for this mode
  )

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.roy$" . roy-mode))

(defcustom roy-command "roy"
  "The Roy command used for evaluating code. Must be in your $PATH."
  :type 'string
  :group 'roy)

(defcustom roy-args-run '("-r")
  "The command line arguments to pass to `roy-command' when running a file."
  :type 'list
  :group 'roy)

;;
;; Commands
;;
(defun roy-repl ()
  "Launch a Roy REPL using `roy-command' as an inferior mode."
  (interactive)
  (unless (comint-check-proc "*RoyREPL*")
    (set-buffer
     (apply 'make-comint "RoyREPL"
            roy-command nil)))
  (pop-to-buffer "*RoyREPL*"))

(provide 'roy-mode)

;;; roy-mode.el ends here
