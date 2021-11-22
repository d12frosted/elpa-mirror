;;; ruby-json-to-hash.el --- Convert JSON to Hash and play with the keys  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Otávio Schwanck dos Santos

;; Author: Otávio Schwanck dos Santos <otavioschwanck@gmail.com>
;; Keywords: tools languages
;; Package-Version: 20211108.351
;; Package-Commit: 383b22bb2e007289ac0dba146787d02ff99d4415
;; Homepage: https://github.com/otavioschwanck/ruby-json-to-hash.el
;; Version: 0.1
;; Package-Requires: ((emacs "27.2") (smartparens "1.11.0") (string-inflection "1.0.16"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a package to help you to insert json into your code and tests.
;; Instead of going to Rails Console and converting json, you just call ruby-json-to-hash-parse-json on on Emacs.
;; You also can create the let from the generated hash or send the let back to the hash.

;;; Code:

(require 'json)
(require 'smartparens)
(require 'string-inflection)

;;;###autoload
(defun ruby-json-to-hash-toggle-let ()
  "Create a let from a key on a hash or send the created let back to the hash.  Useful for rspec."
  (interactive)
  (if (and (ruby-json-to-hash--is-let) (not (looking-at-p "\\([a-zA-Z_]*[a-zA-Z]+\\):")))
      (ruby-json-to-hash-toggle--let-to-hash)
    (ruby-json-to-hash-toggle--hash-to-let)))

(defun ruby-json-to-hash-toggle--hash-to-let ()
  "Send a hash key to a let if possible."
  (if (looking-at-p "\\([a-zA-Z_]*[a-zA-Z]+\\):")
      (ruby-json-to-hash-toggle--hash-to-let-create-let)
    (message "Please use this function on the key element.")))

(defun ruby-json-to-hash-toggle--hash-to-let-create-let ()
  "Send a hash key to a let."
  (let ((key (thing-at-point 'symbol))
        (value (ruby-json-to-hash-toggle--hash-to-let-get-value)))
    (save-excursion
      (insert (string-inflection-underscore-function key))
      (search-backward-regexp "let\\([!]*\\)(:\\([a-zA-Z_]*[a-zA-Z]+\\))" (point-min) t)
      (search-forward ")") (sp-next-sexp)
      (forward-sexp) (end-of-line) (newline-and-indent)
      (if (string-match-p "\n" value)
          (progn (save-excursion
                   (let ((start-point (point)))
                     (insert "let(:" (string-inflection-underscore-function key) ") do\n" value "\nend")
                     (indent-region start-point (point)))))
        (insert "let(:" (string-inflection-underscore-function key) ") { " value " }")))))

(defun ruby-json-to-hash-toggle--hash-to-let-get-value ()
  "Get value to create a new let."
  (let ((value ""))
    (search-forward ":")
    (sp-next-sexp)
    (kill-sexp)
    (setq value (concat value (substring-no-properties (car kill-ring))))
    (while (looking-at-p "\\.\\| ")
      (kill-sexp)
      (setq value (concat value (substring-no-properties (car kill-ring)))))
    value))

(defun ruby-json-to-hash-toggle--let-to-hash ()
  "Send let back to hash if possible."
  (let* ((let-name
          (save-excursion (beginning-of-line) (search-forward ":") (forward-char 1) (thing-at-point 'symbol t)))
         (let-value (ruby-json-to-hash-toggle-let--let-value))
         (point-to-insert (ruby-json-to-hash-toggle--let-beign-used let-name)))
    (if point-to-insert
        (ruby-json-to-hash-togle--send-to-hash point-to-insert let-value)
      (message "Can't find where to put the let =("))))

(defun ruby-json-to-hash-togle--send-to-hash (point-to-insert let-value)
  "Send let to hash.  POINT-TO-INSERT: Point to insert the let value.  LET-VALUE:  Value to be inserted."
  (beginning-of-line)
  (search-forward ")")
  (sp-next-sexp) (kill-sexp)
  (beginning-of-line) (kill-line 1)
  (goto-char point-to-insert)
  (search-forward ":") (sp-next-sexp) (sp-kill-sexp)
  (insert let-value)
  (indent-region point-to-insert (point)))

(defun ruby-json-to-hash-toggle--let-beign-used (let-name)
  "Verify if is possible to send let back to original hash.  LET-NAME:  let key."
  (let ((used-to-find
         (concat let-name ": " let-name "\\|"
                 (string-inflection-lower-camelcase-function let-name) ": " let-name "\\|"
                 (string-inflection-camelcase-function let-name) ": " let-name)))
    (save-excursion
      (if (search-backward-regexp used-to-find (point-min) t)
          (point)
        (if (search-forward used-to-find (point-max) t)
            (progn (search-backward used-to-find) (point))
          nil)))))

(defun ruby-json-to-hash-toggle-let--let-value ()
  "Value to be send back to hash."
  (save-excursion
    (beginning-of-line)
    (search-forward ")") (sp-next-sexp)
    (let* ((raw-value (thing-at-point 'sexp t))
          (value (replace-regexp-in-string "^\n[ ]+\\|\n[ ]+$" ""
     (replace-regexp-in-string "^do\\|end$" "" raw-value))))
      (if (string= (substring-no-properties raw-value 0 1) "{")
          (substring-no-properties value 2 (- (length value) 2))
          value))))

(defun ruby-json-to-hash--is-let ()
  "Verify if current line at cursor is a child let."
  (save-excursion
    (beginning-of-line)
    (if (search-forward-regexp "let\\([!]*\\)(:\\([a-zA-Z_]*[a-zA-Z]+\\))" (point-at-eol) t) t nil)))

;;;###autoload
(defun ruby-json-to-hash-parse-json ()
  "Convert a JSON into ruby hash syntax."
  (interactive)
  (when (not (eq ?{ (char-after))) (search-backward "{"))
  (let* ((initial-point (point))
         (json (json-read-object))
         (end-point (point)))
    (goto-char initial-point)
    (kill-region initial-point end-point)
    (insert "{\n")
    (mapc 'ruby-json-to-hash--insert-key json)
    (insert "\n}")
    (indent-region initial-point (point))
    (delete-trailing-whitespace initial-point (point))
    (ruby-json-to-hash-parse-json--flush-lines initial-point)
    (ruby-json-to-hash-parse-json--clear-extra-commas initial-point)))

(defun ruby-json-to-hash-parse-json--clear-extra-commas (initial-point)
  "Clear extra commas after the conversion to json.  INITIAL-POINT: Point of start."
  (let ((current-point (point)))
    (save-excursion
      (goto-char initial-point)
      (while (search-forward-regexp ", ],$" current-point t)
        (forward-char -4) (delete-char 2)))
    (save-excursion
      (goto-char initial-point)
      (while (search-forward-regexp "},\n\\([  ]+\\)+]" current-point t)
        (forward-line -1) (end-of-line) (delete-char -1)))
    (save-excursion
      (goto-char initial-point)
      (while (search-forward-regexp ",\n\\([  ]+\\)+}" current-point t)
        (forward-line -1) (end-of-line) (delete-char -1)))))

(defun ruby-json-to-hash-parse-json--flush-lines (initial-point)
  "Flush lines after convert json.  INITIAL-POINT: Point of start."
  (let ((current-point (point)))
    (save-excursion
      (goto-char initial-point)
      (while (search-forward-regexp "^\\s-*$" current-point t)
        (kill-line)))))

(defun ruby-json-to-hash--insert-key (key)
  "Insert the key for a conversion.  KEY: key to be inserted."
  (cond
   ((eq (type-of key) 'string) (insert "'" key "', "))
   ((eq (type-of (cdr key)) 'cons) (ruby-json-to-hash--insert-key-hash key))
   ((eq (type-of (cdr key)) 'vector) (ruby-json-to-hash--insert-key-array key))
   (t (ruby-json-to-hash--insert-value key))))

(defun ruby-json-to-hash--insert-key-array (key)
  "Insert the key if it is an array.  KEY: key to be inserted."
  (insert (format "%s" (car key)) ": [")
  (mapc 'ruby-json-to-hash--insert-key-from-array (cdr key))
  (insert "],\n"))

(defun ruby-json-to-hash--insert-key-from-array (key)
  "Insert the key from an array.  KEY: key to be inserted."
  (cond
   ((eq (type-of key) 'string) (ruby-json-to-hash--insert-key key))
   ((eq (type-of key) 'cons)
    (insert " \n{\n")
    (mapc 'ruby-json-to-hash--insert-key key)
    (insert "},\n"))))

(defun ruby-json-to-hash--insert-key-hash (key)
  "Insert the key from if is an hash.  KEY: key to be inserted."
  (insert (format "%s" (car key)) ": {\n ")
  (mapc
   (lambda (hash_key)
     (ruby-json-to-hash--insert-key hash_key)) (cdr key))
  (insert " \n},\n"))

(defun ruby-json-to-hash--insert-value (key)
  "Insert the value if is not an normal type.  KEY: key to be inserted."
  (insert (format "%s" (car key))
          ": " (ruby-json-to-hash--insert-value--insert-by-value-type (cdr key))
          ",\n"))

(defun ruby-json-to-hash--insert-value--insert-by-value-type (key)
  "Insert the value depending of its value type (only for simple types).  KEY: key to be inserted."
  (cond
   ((eq (type-of key) 'string) (concat "'" key "'"))
   ((eq (type-of key) 'symbol) (ruby-json-to-hash--insert-symbol key))
   (t (format "%s" key))))

(defun ruby-json-to-hash--insert-symbol (key)
  "Insert symbol dependinf of type.  KEY: Symbol to be inserted."
  (cond
   ((eq key t) "true")
   ((eq key json-false) "false")
   (t (format "%s" key))))

(provide 'ruby-json-to-hash)
;;; ruby-json-to-hash.el ends here
