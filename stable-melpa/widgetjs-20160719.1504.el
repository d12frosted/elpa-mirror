;;; widgetjs.el --- Widgetjs mode

;; Copyright (C) 2014  Nicolas Petton

;; Author: Nicolas Petton <petton.nicolas@gmail.com>
;; Keywords: help
;; Package-Version: 20160719.1504
;; Package-Commit: 58a0e556b4b96e1d23082a7ec2e8c0d4183a1a24
;; Version: 0.1
;; Package-Requires: ((makey "0.3") (js2-mode "20140114") (js2-refactor "0.6.1") (s "1.9.0"))

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
;; Minor mode for widgetjs.

;;; Code:

(require 's)
(require 'makey)
(require 'js2-refactor)

(defvar widgetjs-mode-map
  (make-sparse-keymap)
  "Keymap for widgetjs-mode.")

(defface widgetjs-html-face
  nil
  "Face used to highlight `html' tags, typically used in
  rendering methods."
  :group 'widgetjs)

(defface widgetjs-html-tag-face
  '((t :foreground "#61afef" :background "#38394c" :weight bold :box t))
  "Face used to highlight `html' tags, typically used in
  rendering methods."
  :group 'widgetjs)

(defface widgetjs-that-face
  '((t :inherit font-lock-keyword-face))
  "Face used to highlight `that' used as the receiver."
  :group 'widgetjs)

(defface widgetjs-prop-face
  '((t :inherit font-lock-keyword-face))
  "Face used to highlight `spec' and `my'."
  :group 'widgetjs)

(defconst widgetjs-font-lock-keywords
  '(("\\<\\(html\\)\\>\\(\\.\\)\\(\\w+\\)"
     (1 'widgetjs-html-face)
     (2 'widgetjs-html-face)
     (3 'widgetjs-html-tag-face prepend))
    ("\\<that\\>" . 'widgetjs-that-face)
    ("\\<spec\\>\\|\\<my\\>" . 'widgetjs-prop-face)))

(define-minor-mode widgetjs-mode
  "Minor mode for handling AMD modules within a JavaScript file."
  :lighter " Wjs"
  :keymap widgetjs-mode-map
  (if widgetjs-mode
      (font-lock-add-keywords nil widgetjs-font-lock-keywords)
    (font-lock-remove-keywords nil widgetjs-font-lock-keywords)))

(defun widgetjs-convert-function (property-name)
  (save-excursion
    (widgetjs-goto-function-node)
    (let* ((function-node (js2-node-at-point))
           (function-name (js2-function-name (js2-node-at-point)))
           (scope (js2-node-get-enclosing-scope function-node))
           (scope (js2-get-defining-scope scope function-name)))
      (widgetjs-replace-occurrences function-name
                                    property-name
                                    scope)
      (widgetjs-convert-definition property-name function-name))))

(defun widgetjs-convert-definition (property-name function-name)
  (let ((end (point)))
    (search-backward-regexp "function[\s\t]+")
    (delete-region (point) end))
  (insert (concat property-name "." function-name))
  (search-forward "(")
  (backward-char 1)
  (insert " = function")
  (search-forward "{")
  (backward-char 1)
  (forward-sexp)
  (unless (looking-at ";")
    (insert ";")))

(defun widgetjs-replace-occurrences (function-name property-name scope)
  (save-excursion
    (let ((nodes nil))
      (js2-visit-ast
       scope
       (lambda (node end-p)
         (when (and (not end-p)
                    (not (js2-function-node-p node))
                    (js2r--local-name-node-p node)
                    (string= function-name (js2-name-node-name node)))
           (push node nodes))
         t))
      (dolist (node nodes)
        (widgetjs-replace-occurrence node property-name)))))

(defun widgetjs-replace-occurrence (node property-name)
  (goto-char (js2-node-abs-pos node))
  (insert (concat property-name  ".")))

(defun widgetjs-goto-function-node ()
  (back-to-indentation)
  (search-forward "function ")
  (search-forward "(")
  (backward-char 1)
  (when (looking-back " ")
    (backward-char 1)))

(defun widgetjs-convert-function-to-my ()
  (interactive)
  (widgetjs-convert-function "my"))

(defun widgetjs-convert-function-to-that ()
  (interactive)
  (widgetjs-convert-function "that"))

(defun widgetjs-make-string-translatable ()
  (interactive)
  (let* ((node (js2-node-at-point))
         (beg (js2-node-abs-pos node))
         (end (js2-node-abs-end node)))
    (unless (js2-string-node-p node)
      (error "Not on a string node"))
    (save-excursion
      (goto-char beg)
      (insert "_(")
      (goto-char (+ 2 end))
      (insert ")"))))

(defun widgetjs-expand-html ()
  (interactive)
  (save-excursion
    (back-to-indentation)
    (let ((beg (point)))
      (end-of-line)
      (widgetjs-expand-html-region beg (point)))))

(defun widgetjs-expand-html-region (beg end)
  (interactive)
  (let ((expansion-string (buffer-substring beg end)))
    (insert (concat (widgetjs-parse-html expansion-string) ";"))
    (delete-region beg end)
    (indent-region beg (point))))

(defun widgetjs-parse-html (string)
  (let ((html-list (read string)))
    (if (listp (car html-list))
        (widgetjs-parse-nodes html-list)
      (widgetjs-parse-node html-list))))

(defun widgetjs-parse-nodes (nodes)
  (let ((result ""))
    (dolist (node nodes)
      (setq result (concat result " " (widgetjs-parse-node node) ";\n")))
    result))

(defun widgetjs-parse-node (node)
  "NODE can be either a string or a list"
  (if (stringp node)
      (concat "'" node "'")
    (widgetjs-parse-list-node node)))

(defun widgetjs-parse-list-node (node)
  "Parsing rules:
- The car of NODE is the tag
- The cdr of NODE contains its children"
  (let* ((tag (widgetjs-parse-tag (car node)))
         (attributes (widgetjs-parse-attributes (car node)))
         (children (cdr node))
         (result (concat "html." tag "(")))
    (when attributes
      (setq result (concat result attributes)))
    (if children
        (progn
          (if attributes
              (setq result (concat result ", ")))
          (setq result (concat result "\n"))
          (setq result (concat result
                               (widgetjs-parse-children children)
                               "\n"))))
    (setq result (concat result ")"))
    result))

(defun widgetjs-parse-tag (symbol)
  (let ((result (symbol-name symbol)))
    (setq result (replace-regexp-in-string  "\\.\.*" "" result))
    (setq result (replace-regexp-in-string  "\\@\.*" "" result))
    result))

(defun widgetjs-parse-children (children)
  "CHILDREN should be a list of HTML nodes (lists themselves), or
a string."
  (let ((result ""))
    (if (listp children)
        (dolist (node children)
          (setq result (concat result (widgetjs-parse-node node)))
          (unless (eq (car (last children)) node)
            (setq result (concat result ",\n"))))
      (setq result (concat result (widgetjs-parse-node children))))
    result))

(defun widgetjs-parse-attributes (symbol)
  (let* ((name (symbol-name symbol))
         (class (widgetjs-parse-class name))
         (id (widgetjs-parse-id name))
         (result nil))
    (when (or class id)
      (setq result "{")
      (when class
        (setq result (concat result "klass: '" class "'")))
      (when id
        (when class
          (setq result (concat result ",")))
        (setq result (concat result " id: '" id "'")))
      (setq result (concat result "}")))
    result))

(defun widgetjs-parse-id (name)
  (save-match-data
    (when (string-match "@\\([a-zA-Z0-9-_]+\\)" name)
      (match-string 1 name))))

(defun widgetjs-parse-class (name)
  (save-match-data
    (when (string-match "\\(\\.[a-zA-Z0-9-_]+\\)+" name)
      (s-trim (mapconcat #'identity
                         (split-string (match-string 0 name) "\\.") " ")))))

(defun widgetjs-initialize-makey-group ()
  (interactive)
  (makey-initialize-key-groups
   '((widgetjs
      (description "Widgetjs")
      (actions
       ("Convert function"
        ("m" "Convert function to my" widgetjs-convert-function-to-my)
        ("t" "Convert function to that" widgetjs-convert-function-to-that))
       ("HTML expansion"
        ("h" "Render HTML expansion" widgetjs-expand-html))
       ("Translation"
        ("l" "Translatable string" widgetjs-make-string-translatable))))))
  (makey-key-mode-popup-widgetjs))

(define-key widgetjs-mode-map (kbd "C-c C-w") #'widgetjs-initialize-makey-group)

(provide 'widgetjs)
;;; widgetjs.el ends here
