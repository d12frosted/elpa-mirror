;;; heex-ts-mode.el --- Major mode for Heex with tree-sitter support -*- lexical-binding: t; -*-

;; Copyright (C) 2022, 2023 Wilhelm H Kirschbaum

;; Author           : Wilhelm H Kirschbaum
;; Version          : 1.0
;; Package-Version: 20230210.757
;; Package-Commit: 6b8f675d754dc615c4ae6d0a94ddbae5f12fba43
;; URL              : https://github.com/wkirschbaum/elixir-ts-mode
;; Package-Requires : ((emacs "29"))
;; Created          : November 2022
;; Keywords         : heex languages tree-sitter

;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.

;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package defines heex-ts-mode which is a major mode for editing
;; Elixir and Heex files.

;; Features

;; * Indent

;; elixir-ts-mode tries to replicate the indentation provided by
;; mix format, but will come with some minor differences.

;; * IMenu
;; * Navigation
;; * Which-fun

;;; Code:

(require 'treesit)
(eval-when-compile (require 'rx))

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-node-child "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-install-language-grammar "treesit.el")

(defcustom heex-ts-mode-indent-offset 2
  "Indentation of Heex statements."
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'heex)

(defface heex-ts-font-keyword-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @keyword tag.")

(defface heex-ts-font-bracket-face
  '((t (:inherit default)))
  "For use with @keyword tag.")

(defface heex-ts-font-constant-face
  '((t (:inherit font-lock-doc-face)))
  "For use with @keyword tag.")

(defface heex-ts-font-comment-face
  '((t (:inherit font-lock-comment-face)))
  "For use with @keyword tag.")

(defface heex-ts-font-tag-face
  '((t (:inherit font-lock-function-name-face)))
  "For use with @tag tag.")

(defface heex-ts-font-attribute-face
  '((t (:inherit font-lock-variable-name-face)))
  "For use with @keyword tag.")

(defface heex-ts-font-string-face
  '((t (:inherit font-lock-constant-face)))
  "For use with @keyword tag.")

(defface heex-ts-font-module-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @keyword tag.")

(defface heex-ts-font-function-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @keyword tag.")

(defface heex-ts-font-delimeter-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @keyword tag.")

(defconst heex-ts-mode--brackets
  '("%>" "--%>" "-->" "/>" "<!" "<!--" "<" "<%!--" "<%" "<%#"
    "<%%=" "<%=" "</" "</:" "<:" ">" "{" "}"))

(defconst heex-ts-mode--brackets-vector
  (apply #'vector heex-ts-mode--brackets))

(defvar heex-ts-mode-default-grammar-sources
  '((heex . ("https://github.com/phoenixframework/tree-sitter-heex.git"))))

(defvar heex-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?< "(>" table)
    (modify-syntax-entry ?> ")<" table)
    table)
  "Heex mode syntax table.")

;; There seems to be no parent directive block
;; so we ignore it for until we learn how heex treesit
;; represents directive blocks
;; https://github.com/phoenixframework/tree-sitter-heex/issues/28
(defvar heex-ts-mode--indent-rules
  (let ((offset heex-ts-mode-indent-offset))
    `((heex
       ((parent-is "fragment") point-min 0)
       ((node-is "end_tag") parent-bol 0)
       ((node-is "end_component") parent-bol 0)
       ((node-is "end_slot") parent-bol 0)
       ((node-is ">") parent-bol 0)
       ((parent-is "component") parent-bol ,offset)
       ((parent-is "slot") parent-bol ,offset)
       ((parent-is "tag") parent-bol ,offset)
       (no-node parent-bol ,offset)))))

(defvar heex-ts-mode--font-lock-settings
  (when (treesit-available-p)
    (treesit-font-lock-rules
     :language 'heex
     :feature 'heex-doctype
     '((doctype) @heex-ts-font-constant-face)

     :language 'heex
     :feature 'heex-comment
     '((comment) @heex-ts-font-comment-face)

     :language 'heex
     :feature 'heex-bracket
     `(,heex-ts-mode--brackets-vector @heex-ts-font-bracket-face)

     :language 'heex
     :feature 'heex-tag
     `([(tag_name) (slot_name)] @heex-ts-font-tag-face)

     :language 'heex
     :feature 'heex-attribute
     `((attribute_name) @heex-ts-font-attribute-face)

     :language 'heex
     :feature 'heex-keyword
     `((special_attribute_name) @heex-ts-font-keyword-face)

     :language 'heex
     :feature 'heex-string
     `([(attribute_value) (quoted_attribute_value)] @heex-ts-font-string-face)

     :language 'heex
     :feature 'heex-component
     `([
        (component_name) @heex-ts-font-tag-face
        (module) @heex-ts-font-module-face
        (function) @heex-ts-font-function-face
        "." @heex-ts-font-delimeter-face
        ])))
  "Tree-sitter font-lock settings.")

(defun heex-ts-mode--comment-region (beg end &optional _arg)
  "Comments the region between BEG and END."
  (save-excursion
    (goto-char beg)
    (insert comment-start " ")
    (goto-char end)
    (goto-char (pos-eol))
    (forward-comment (- (point-max)))
    (insert " " comment-end)))

(defun heex-ts-mode--defun-name (node)
  "Return the name of the defun NODE.
Return nil if NODE is not a defun node or doesn't have a name."
  (pcase (treesit-node-type node)
    ((or "component" "slot" "tag")
     (string-trim (treesit-node-text
                   (treesit-node-child (treesit-node-child node 0) 1)
                   nil)))
    (_ nil)))

(defun heex-ts-install-grammar ()
  "Experimental function to install the tree-sitter-heex grammar."
  (interactive)
  (if (and (treesit-available-p) (boundp 'treesit-language-source-alist))
      (let ((treesit-language-source-alist
             (append
              treesit-language-source-alist
              heex-ts-mode-default-grammar-sources)))
        (if (y-or-n-p
             (format
              (concat "The following language grammar repository which will be "
                      "downloaded and installed "
                      "%s, proceed?")
              (cadr (assoc 'heex treesit-language-source-alist))))
            (progn
              (treesit-install-language-grammar 'elixir)
              (treesit-install-language-grammar 'heex))))
    (display-warning
     'treesit
     (concat "Cannot install grammar because"
             " "
             "tree-sitter library is not compiled with Emacs"))))

(defun heex-ts-mode-treesit-ready-p ()
  (let ((language-version 14))
    (and (treesit-ready-p 'heex)
         (if (< (treesit-language-abi-version 'heex) language-version)
             (progn
               (display-warning
                'treesit
                (format "Cannot activate tree-sitter for %s, because tree-sitter language version %s or later is required" "heex-ts-mode" language-version))
               nil)
           t))))

(defun heex-ts-mode--forward-sexp (&optional arg)
  (interactive "^p")
  (or arg (setq arg 1))
  (funcall
   (if (> arg 0) #'treesit-end-of-thing #'treesit-beginning-of-thing)
   (rx bol
       (or "attribute" "directive" "tag" "component" "slot")
       eol)
   (abs arg)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.[hl]?eex\\'" . heex-ts-mode))

;;;###autoload
(define-derived-mode heex-ts-mode prog-mode "Heex"
  "Major mode for editing Heex, powered by tree-sitter."
  :group 'heex
  :syntax-table heex-ts-mode--syntax-table

  ;; Comments.
  (setq-local comment-start "<!-- ")
  (setq-local comment-start-skip (rx (or "<!--")
                                     (* (syntax whitespace))))
  (setq-local comment-end "-->")
  (setq-local comment-end-skip (rx (* (syntax whitespace))
                                   (group (or "-->"))))

  (when (heex-ts-mode-treesit-ready-p)
    (treesit-parser-create 'heex)

    (setq-local comment-region-function 'heex-ts-mode--comment-region)

    (setq-local forward-sexp-function #'heex-ts-mode--forward-sexp)

    ;; Electric.
    (setq-local electric-indent-chars
                (append ">" electric-indent-chars))

    ;; Navigation.
    (setq-local treesit-defun-type-regexp
                (rx bol (or "component" "tag" "slot") eol))
    (setq-local treesit-defun-name-function #'heex-ts-mode--defun-name)

    ;; Imenu
    (setq-local treesit-simple-imenu-settings
                '(("Component" "\\`component\\'" nil nil)
                  ("Slot" "\\`slot\\'" nil nil)
                  ("Tag" "\\`tag\\'" nil nil)))

    (setq-local treesit-font-lock-settings heex-ts-mode--font-lock-settings)

    (setq-local treesit-simple-indent-rules heex-ts-mode--indent-rules)

    (setq-local treesit-font-lock-feature-list
                '(( heex-doctype heex-comment )
                  ( heex-string heex-keyword heex-component heex-tag heex-attribute )
                  ( heex-bracket )))

    (treesit-major-mode-setup)))

(provide 'heex-ts-mode)
;;; heex-ts-mode.el ends here
