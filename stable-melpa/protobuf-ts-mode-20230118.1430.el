;;; protobuf-ts-mode.el --- Tree sitter support for Protocol Buffers (proto3 only) -*- lexical-binding: t; -*-

;; Author           : ookami <mail@ookami.one>
;; Version          : 1.0
;; Package-Version: 20230118.1430
;; Package-Commit: b65dc2379915fc846ff2578be5b652081bea193b
;; URL              : https://git.ookami.one/cgit/protobuf-ts-mode
;; Package-Requires : ((emacs "29"))
;; Keywords         : protobuf languages tree-sitter

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Use tree-sitter for font-lock, imenu, indentation, and navigation
;; of protocol buffers files.  (proto3 only)

;;; Code:

(require 'treesit)
(eval-when-compile (require 'rx))

(defcustom protobuf-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `protobuf-ts-mode'."
  :type 'integer
  :safe 'integerp
  :group 'protobuf)

(defvar protobuf-ts-mode--indent-rules
  `((proto
     ((node-is ")") parent-bol 0)
     ((node-is "}") parent-bol 0)
     ((parent-is "service") parent-bol protobuf-ts-mode-indent-offset)
     ((parent-is "rpc") parent-bol protobuf-ts-mode-indent-offset)
     ((parent-is "message_body") parent-bol protobuf-ts-mode-indent-offset)
     ((parent-is "enum_body") parent-bol protobuf-ts-mode-indent-offset))))

(defvar protobuf-ts-mode--keywords
  '("optional" "repeated"
    "message" "enum" "service" "rpc"
    "syntax" "package" "import"
    "option" "returns"))

(defvar protobuf-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'proto
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'proto
   :feature 'keyword
   `([,@protobuf-ts-mode--keywords] @font-lock-keyword-face)

   :language 'proto
   :feature 'string
   '((string) @font-lock-string-face)

   :language 'proto
   :feature 'type
   '((service_name (identifier) @font-lock-type-face)
     (message_name (identifier) @font-lock-type-face)
     (enum_name (identifier) @font-lock-type-face)
     (package (full_ident) @font-lock-type-face)
     ((key_type) @font-lock-type-face)
     ((type) @font-lock-type-face)
     ((message_or_enum_type) @font-lock-type-face)
     "map" @font-lock-type-face)

   :language 'proto
   :feature 'function
   '((rpc (rpc_name (identifier) @font-lock-function-name-face)))

   :language 'proto
   :feature 'variable
   '((identifier) @font-lock-variable-name-face)))

(defun protobuf-ts-mode--defun-name (node)
  "Return the defun name of NODE."
  (treesit-node-text (treesit-search-subtree node "^identifier$" nil t) t))

;;;###autoload
(define-derived-mode protobuf-ts-mode prog-mode "Protocol-Buffers"
  "Major mode for editing Protocol Buffers description language."
  :group 'protobuf
  (when (treesit-ready-p 'proto)
    (treesit-parser-create 'proto)

    ;; Comments
    (setq-local comment-start "/* ")
    (setq-local comment-end "*/ ")
    (setq-local comment-start-skip (rx (or (seq "/" (+ "/"))
                                           (seq "/" (+ "*")))
                                       (* (syntax whitespace))))

    ;; Font-lock
    (setq-local treesit-font-lock-settings protobuf-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '(( comment)
                  ( keyword string)
                  ( type function variable)))

    ;; Imenu
    (setq-local treesit-simple-imenu-settings
                `(("Service" "\\`service_name\\'" nil nil)
                  ("RPC" "\\`rpc_name\\'" nil nil)
                  ("Message" "\\`message_name\\'" nil nil)
                  ("Enum" "\\`enum_name'" nil nil)))

    ;; Indent
    (setq-local treesit-simple-indent-rules protobuf-ts-mode--indent-rules)

    ;; Navigation
    (setq-local treesit-defun-type-regexp
                (rx string-start
                    (or "service" "rpc" "message" "enum")
                    string-end))
    (setq-local treesit-defun-name-function #'protobuf-ts-mode--defun-name)

    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.proto\\'" . protobuf-ts-mode))

(provide 'protobuf-ts-mode)

;;; protobuf-ts-mode.el ends here
