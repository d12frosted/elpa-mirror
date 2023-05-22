;;; go-add-tags.el --- Add field tags for struct fields -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-go-add-tags
;; Package-Version: 20211122.1812
;; Package-Commit: 93ecde9f82bc960493eaf6921d46a5adc3699ffc
;; Version: 0.04
;; Package-Requires: ((emacs "24.3") (s "1.11.0"))

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

;; Add field tags (such as json, yaml, toml, datastore and
;; mapstructure) for struct fields.  This package is inspired
;; by vim-go's GoAddTags command

;;; Code:

(require 's)
(require 'cl-lib)

(defgroup go-add-tags nil
  "Add field tag for struct fields."
  :group 'go)

(defcustom go-add-tags-style 'snake-case
  "How to convert field in tag from field name."
  :type '(choice (const :tag "snake_case" snake-case)
                 (const :tag "camelCase" lower-camel-case)
                 (const :tag "UpperCamelCase" upper-camel-case)
                 (const :tag "Use original field name" original)))

(defcustom go-add-tags-fields-tags
  '("json" "yaml" "toml" "datastore" "mapstructure")
  "List of field tags offered as completion candidates."
  :type '(repeat (symbol :tag "Field")))

(defvar go-add-tags--style-functions
  '((snake-case . s-snake-case)
    (camel-case . s-lower-camel-case)
    (upper-camel-case . s-upper-camel-case)))

(defun go-add-tags--inside-struct-p (begin)
  (save-excursion
    (goto-char begin)
    (ignore-errors
      (backward-up-list))
    (looking-back "struct\\s-*" (line-beginning-position))))

(defun go-add-tags--tag-string (tags field)
  (mapconcat (lambda (tag)
               (format "%s:\"%s\"" tag field))
             tags
             " "))

(defun go-add-tags--tag-exist-p ()
  (let ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (string-match-p "`[^`]+`" line)))

(defun go-add-tags--insert-tag (tags field)
  (dolist (tag tags)
    (save-excursion
      (let ((re (concat tag ":\"[^\"]+\""))
            (tag-field (concat tag ":" "\"" field "\"")))
        (if (re-search-forward re (line-end-position) t)
            (replace-match tag-field)
          (search-forward "`" (line-end-position) t 2)
          (backward-char 1)
          (insert " " tag-field))))))

(defun go-add-tags--overwrite-or-insert-tag (tags field conv-fn)
  (let* ((prop (funcall conv-fn field))
         (exist-p (go-add-tags--tag-exist-p)))
    (if (not exist-p)
        (insert (format " `%s`" (go-add-tags--tag-string tags prop)))
      (go-add-tags--insert-tag tags prop))))

(defun go-add-tags--struct-name ()
  (save-excursion
    (when (ignore-errors (backward-sexp 1) t)
      (back-to-indentation)
      (when (looking-at "\\(\\S-+\\)\\s-+\\(?:\\[\\]\\)?struct\\s-*")
        (match-string-no-properties 1)))))

(defun go-add-tags--insert-tags (tags begin end conv-fn)
  (save-excursion
    (let ((end-marker (make-marker)))
      (set-marker end-marker end)
      (goto-char begin)
      (goto-char (line-beginning-position))
      (while (and (<= (point) end-marker) (not (eobp)))
        (let ((bound (min end-marker (line-end-position))))
          (cond ((re-search-forward "^\\s-*\\(\\S-+\\)\\s-+\\(\\S-+\\)" bound t)
                 (let ((field (match-string-no-properties 1))
                       (type-end (match-end 2))
                       (line (buffer-substring-no-properties
                              (line-beginning-position) (line-end-position))))
                   (unless (string-match-p "struct\\s-*+{" line)
                     (goto-char (min bound type-end))
                     (go-add-tags--overwrite-or-insert-tag tags field conv-fn))))
                ((re-search-forward "^\\s-*}" bound t)
                 (unless (zerop (current-indentation))
                   (let ((field (go-add-tags--struct-name)))
                     (when field
                       (go-add-tags--overwrite-or-insert-tag tags field conv-fn)))))))
        (forward-line 1)))))

(defun go-add-tags--style-candidates (field)
  (cl-loop for (_ . func) in go-add-tags--style-functions
           collect (cons (funcall func field) func) into candidates
           finally return (append candidates (list (cons "Original" #'identity)))))

(defun go-add-tags--prompt (candidates)
  (cl-loop for cand in candidates
           for i = 1 then (1+ i)
           collect (format "[%d] %s" i cand) into parts
           finally
           return (mapconcat #'identity parts " ")))

(defun go-add-tags--read-style-function ()
  (let* ((candidates (go-add-tags--style-candidates "FieldName"))
         (len (length candidates))
         (prompt (go-add-tags--prompt (mapcar #'car candidates)))
         ret finish)
    (while (not finish)
      (let* ((input (read-char prompt))
             (num (- input ?0)))
        (when (and (<= 1 num) (<= num len))
          (setq finish t)
          (setq ret (cdr (nth (1- num) candidates))))))
    ret))

;;;###autoload
(defun go-add-tags (tags begin end conv-fn)
  "Add field tags for struct fields."
  (interactive
   (list
    (completing-read-multiple "Tags: " go-add-tags-fields-tags)
    (or (and (use-region-p) (region-beginning)) (line-beginning-position))
    (or (and (use-region-p) (region-end)) (line-end-position))
    (if current-prefix-arg
        (go-add-tags--read-style-function)
      (assoc-default go-add-tags-style go-add-tags--style-functions))))
  (deactivate-mark)
  (let ((inside-struct-p (go-add-tags--inside-struct-p begin)))
    (unless inside-struct-p
      (user-error "Here is not struct"))
    (save-excursion
      (go-add-tags--insert-tags tags begin end (or conv-fn #'identity)))))

(provide 'go-add-tags)

;;; go-add-tags.el ends here
