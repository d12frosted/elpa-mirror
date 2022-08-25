;;; jastadd-ast-mode.el --- Major mode for editing JastAdd AST files

;; Copyright (c) 2016 Rudi Schlatte <rudi@constantly.at>

;; Author: Rudi Schlatte <rudi@constantly.at>
;; URL: https://github.com/rudi/jastadd-ast-mode
;; Package-Commit: a98a5eef274d8eedabc7467874edf4338c9a012e
;; Package-Version: 20200926.1820
;; Package-X-Original-Version: 0.2
;; Package-Requires: ((emacs "25"))
;; Keywords: languages
;; Version: 0.2

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:
;;
;; This mode provides light support for editing of JastAdd AST definition
;; files in Emacs.  JastAdd is a meta-compilation system that supports
;; Reference Attribute Grammars (RAGs); see http://jastadd.org.  Currently,
;; this mode supports syntax highlighting, comment support and buffer
;; navigation via imenu.
;;

;;; Code:


(defvar jastadd-ast--font-lock-defaults
  `(("abstract" . font-lock-keyword-face)
    (,(rx word-start (char upper) (* (char alnum)) word-end)
     . font-lock-type-face)
    ))

(defvar jastadd-ast--imenu-generic-expression
  `(("*Abstract Definitions*"
     ,(rx bol (* whitespace) "abstract" (* whitespace)
          (group (char upper) (* (char alnum)))
          (* whitespace) ":")
     1)
    (nil
     ,(rx bol (* whitespace)
          (group (char upper) (* (char alnum)))
          (* whitespace) ":")
     1)))

;;;###autoload
(define-derived-mode jastadd-ast-mode prog-mode "JastAdd"
  "Major mode for editing JastAdd AST files.
\\{jastadd-ast-mode-map}"
  (make-local-variable 'comment-start)
  (setq comment-start "//")
  (make-local-variable 'comment-end)
  (setq comment-end "")
  (modify-syntax-entry ?/ ". 124" jastadd-ast-mode-syntax-table)
  (modify-syntax-entry ?* ". 23b" jastadd-ast-mode-syntax-table)
  (modify-syntax-entry ?\n ">" jastadd-ast-mode-syntax-table)
  (modify-syntax-entry ?\^m ">" jastadd-ast-mode-syntax-table)

  (setq font-lock-defaults '(jastadd-ast--font-lock-defaults))

  (setq imenu-generic-expression jastadd-ast--imenu-generic-expression)
  (imenu-add-menubar-index)
  (if (featurep 'speedbar)
      (speedbar-add-supported-extension ".ast")
    (add-hook 'speedbar-load-hook
              (lambda () (speedbar-add-supported-extension ".ast"))))
  )

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ast\\'" . jastadd-ast-mode) t)

(provide 'jastadd-ast-mode)

;;; jastadd-ast-mode.el ends here
