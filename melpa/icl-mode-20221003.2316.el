;;; icl-mode.el --- Support for IEEE 1687 ICL/PDL  -*- lexical-binding: t; -*-

;; Author: Troy Hinckley <troy.hinckley@dabrev.com>
;; Version: 0.1.0
;; Package-Version: 20221003.2316
;; Package-Commit: 1ef19c3c1c7f2667796907391d5337bbc2d73df3
;; Package-Requires: ((emacs "25.2"))
;; Homepage: https://github.com/CeleritasCelery/icl-mode

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package adds support for the formats in the IEEE 1687-2014 spec. It
;; provides the icl-mode major mode that includes basic syntax highlighting,
;; indentation, and imenu support for the Instrument Connectivity Language
;; (ICL). Also sets up pdl files to better support the Procedural Description
;; Language (PDL) extensions.
;;
;; For more info, see the IEEE spec:
;; https://standards.ieee.org/ieee/1687/3931/

;;; Code:

(defvar tcl-proc-list)
(defvar tcl-keyword-list)
(defvar tcl-proc-regexp)
(defvar tcl-imenu-generic-expression)
(defvar c-basic-offset)
(declare-function tcl-set-font-lock-keywords "tcl")
(declare-function tcl-set-proc-regexp "tcl")
(declare-function c-indent-line "cc-cmds")

(defvar icl-imenu-generic-expression
  `(("modules" ,(rx bol "Module" (+ " ") (group (1+ (any alnum "_-"))) symbol-end) 1)
    ("instances" ,(rx bol (+ " ") "Instance" (+ " ") (group (1+ (any alnum "_-"))) symbol-end) 1))
  "Imenu expression for ICL modules and instances.")

(defvar icl-font-lock-keywords
  ;; Attribute is a non-standard keyword, but sometimes seen in vendor ICL
  `((,(rx symbol-start "Attribute" symbol-end) 0 font-lock-constant-face)
    ;; The three types of declarations we want to highlight
    (,(rx symbol-start (group (or "Instance" "Module" "Enum")) (+ " ") (group (1+ (any alnum "_"))))
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face))
    ;; Keywords are PascalCase. So we check for upper followed by lower, but
    ;; also explicitly handle the tap keywords which don't have the second
    ;; letter lowercase
    (,(rx bol (0+ " ") (group (or (and upper lower) "TRST" "TCK" "TMS") (1+ alnum)) " ")
     1 font-lock-keyword-face)
    ;; For some reason this keyword does not get highlighted consistently,
    ;; so adding it explicitly
    (,(rx symbol-start "InputPort" symbol-end) 0 font-lock-keyword-face)
    ;; Highlight numbers
    (,(rx (char " [':+-") (group (opt (char "bh")) (1+ digit))) 1 font-lock-type-face)
    ;; Make the hierachy seperator stand out
    (,(rx ".") 0 'error)
    ;; variables like $WIDTH
    (,(rx "$" (group alpha (1+ (any alnum "_")))) 1 font-lock-variable-name-face)
    ;; Used in Instance and Mux statements
    (,(rx (+ " ") (group (or "Of" "SelectedBy"))) 1 font-lock-builtin-face))
  "Keywords for ICL selected by try to maximize readability of collateral.")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.icl\\'" . icl-mode))

(add-to-list 'auto-mode-alist '("\\.pdl\\'" . tcl-mode))

(defun icl-broken-line-p ()
  "Check if the line is split across a declaration.
For example:

Instance x Of
    y {}"
  (save-excursion
    (forward-line -1)
    (end-of-line)
    (skip-syntax-backward " " (line-beginning-position))
    (save-match-data
      (looking-back (rx (or "Of" "SelectedBy" "=")) (line-beginning-position)))))

(defun icl-indent-line ()
  "Indent like C, unless we have a split declaration."
  (interactive)
  (let ((c-basic-offset (if (icl-broken-line-p)
                            (1+ c-basic-offset)
                          c-basic-offset)))
    (c-indent-line)))

;;;###autoload
(defun icl-add-pdl-keywords ()
  "Add PDL keywords to `tcl-mode'."
  (require 'tcl)
  (push "iProc" tcl-proc-list)
  (push "iTopProc" tcl-proc-list)
  (push "iProc" tcl-keyword-list)
  (push "iTopProc" tcl-keyword-list)
  (push "iProcsForModule" tcl-keyword-list)
  (tcl-set-proc-regexp)
  (tcl-set-font-lock-keywords)
  (setq tcl-imenu-generic-expression
        `((nil ,(concat tcl-proc-regexp "\\([-A-Za-z0-9_:+*]+\\)") 2))))

;;;###autoload
(define-derived-mode icl-mode c-mode "ICL"
  "Major mode for IEEE 1687 ICL."
  (setq-local c-basic-offset 3)
  (setq-local indent-line-function #'icl-indent-line)
  (setq-local font-lock-defaults '(icl-font-lock-keywords))
  (setq-local comment-start "//")
  (setq-local comment-end "")
  (setq-local imenu-generic-expression icl-imenu-generic-expression)
  (modify-syntax-entry ?\' "." icl-mode-syntax-table)
  (modify-syntax-entry ?$ "." icl-mode-syntax-table))


(provide 'icl-mode)

;;; icl-mode.el ends here
