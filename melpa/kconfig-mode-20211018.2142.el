;;; kconfig-mode.el --- Major mode for editing Kconfig files

;; Copyright © 2014 Yu Peng
;; Copyright © 2014 Michal Sojka
;; Copyright © 2019 Dela Anthonio

;; Author: Dela Anthonio <dell.anthonio@gmail.com>
;; Homepage: https://github.com/delaanthonio/kconfig-mode
;; Keywords: kconfig, languages, linux, kernel
;; Package-Version: 20211018.2142
;; Package-Commit: 241436a507782d18f09dab7d1f373ddea60fad3d
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a major mode for editing kconfig files.

;; Setup:

;; (require 'kconfig-mode)

;;; Code:

(require 'rx)

(defgroup kconfig nil
  "Kconfig major mode"
  :group 'languages)

(defconst kconfig-mode-syntax-table
  (let ((syntax-table (make-syntax-table)))

    ;; python style comment: “# …”
    (modify-syntax-entry ?# "<" syntax-table)
    (modify-syntax-entry ?\n ">" syntax-table)

    ;; Strings
    (modify-syntax-entry ?\" "\"" syntax-table)

    ;; `_' as being a valid part of a word
    (modify-syntax-entry ?_ "w" syntax-table)

    ;; `=' as a separator.
    ;; e.g. HOTPLUG_PCI=y
    (modify-syntax-entry ?= "-" syntax-table)
    syntax-table)
  "Syntax table for `kconfig-mode'.")

(defconst kconfig-type-keywords
  '("bool" "boolean" "hex" "int" "string" "tristate"))

(defconst kconfig-config-keywords
  '("def_bool" "default" "depends on" "prompt" "select" "range"))

(defconst kconfig-defun-keywords
  '("config"))

(defconst kconfig-doc-keywords
  '("---help---" "help")
  ;; "Keywords before a description"
  )

(defconst kconfig-top-level-keywords
  '("choice" "endchoice" "comment" "if" "endif" "menu" "endmenu" "menuconfig" "source"))

(defconst kconfig-keywords
  (append kconfig-top-level-keywords kconfig-config-keywords kconfig-defun-keywords kconfig-doc-keywords))

(defconst kconfig-mode-font-lock-defaults
  `(
    ;; Documentation
    (,(rx-to-string
       `(and
             line-start space space (+ space) (group(+ not-newline)) line-end
             )
       t)
     1 font-lock-doc-face t)
    ;; keywords
    (,(rx-to-string
       `(and  symbol-start (group (or ,@kconfig-keywords)) symbol-end)
       t)
     1 font-lock-keyword-face)
    ;; types
    (,(rx-to-string
       `(and word-start (group (or ,@kconfig-type-keywords)) word-end)
       t)
     1 font-lock-type-face)
    ;; constants
    (,(rx-to-string
       `(and word-start (group (or "y" "n")) word-end)
       t)
     1 font-lock-constant-face)
     (,(rx-to-string
        `(and word-start "default" word-end (+ space)
              word-start (group (\? "0x") (+ hex)) word-end)
        t)
     1 font-lock-constant-face)
    ;; Config declarations
    (,(rx-to-string
       `(and line-start word-start (or ,@kconfig-defun-keywords) word-end
             (+ space) word-start (group (+ (or alnum "_"))) word-end)
       t)
     1 font-lock-function-name-face t)
    )   "Font lock faces highlighting for `kconfig-mode'.")

(defvar kconfig-headings
  '("bool" "int" "boolean" "hex" "tristate" "string" "def_bool" "depends on"
    "select" "help" "---help---" "default" "prompt" "range" "choice" "endchoice"
    "config" "comment" "menu" "endmenu" "if" "endif" "menuconfig" "source"))

(defun kconfig-outline-level ()
  "Kconfig function to compute nesting level."
  (let ((prefix (match-string 0))
        (result 0))
    (dotimes (i (length prefix))
      (setq result (+ result
                      (if (equal (elt prefix i) ?\s)
                          1 tab-width))))
    result))

(defun kconfig-completion-at-point ()
  "Kconfig completion function added to `completion-at-point-functions'."
  (let* ((bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end kconfig-headings . nil )))

(defconst kconfig-imenu-generic-expression
  '(("Config" "^config *\\(.+\\)" 1)))

;;;###autoload
(define-derived-mode kconfig-mode prog-mode "Kconfig"
  "Major mode for editing Kconfig files in the Linux kernel."
  (setq-local comment-start "#")
  (setq-local comment-padding 1)
  (setq-local comment-end "")
  (setq-local font-lock-defaults '((kconfig-mode-font-lock-defaults) nil nil))
  (setq-local outline-regexp (concat "^[\t ]*" (regexp-opt kconfig-headings)))
  (setq-local outline-level 'kconfig-outline-level)
  (setq-local imenu-generic-expression kconfig-imenu-generic-expression)
  (add-hook 'completion-at-point-functions #'kconfig-completion-at-point nil 'local)

  :group 'kconfig
  :syntax-table kconfig-mode-syntax-table)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\Kconfig\\'" . kconfig-mode))

(provide 'kconfig-mode)
;;; kconfig-mode.el ends here
