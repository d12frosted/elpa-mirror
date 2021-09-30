;;; literal-string.el --- edit string literals in a dedicated buffer -*- lexical-binding: t -*-

;; Copyright 2017-2019 Joost Diepenmaat

;; Author: Joost Diepenmaat <joost@zeekat.nl>
;; Keywords: lisp, tools, docs
;; Package-Commit: afffa86e626798ee9f9188ea3be2d5ee6ad17c39
;; URL: https://github.com/joodie/literal-string-mode/
;; Package-Requires: ((emacs "25") (edit-indirect "0.1.5"))
;; Package-Version: 20191023.733
;; Package-X-Original-Version: 0.5

;; Contributors:
;; - Joost Diepenmaat
;; - Syohei YOSHIDA

;;; Commentary:
;;;
;;; Literal String Mode is a minor mode for editing multi-line literal
;;; strings in a dedicated buffer.
;;;
;;; When enabled, edit the literal string at point using C-c "
;;; (literal-string-edit-string), this will copy the (unescaped and
;;; deindented) content of the string to a dedicated literal string
;;; editing buffer using `edit-indirect`.
;;;
;;; To exit the current literal string buffer and copy the edited
;;; string back into the original source buffer with correct quoting
;;; and escape sequences, press C-c c (edit-indirect-commit)
;;;
;;; To discard your changes to the editing buffer, press C-c C-k
;;; (edit-indirect-abort)
;;;
;;; To enable literal-string-mode in your preferred programming modes,
;;; turn it on using the relevant mode hooks.
;;;
;;; You can customize `literal-string-editing-mode` to set the major
;;; mode of the editing buffer.  (For instance, to markdown-mode).

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'subr-x)

(defun literal-string--inside-string? ()
  "Return non-nil if inside string, else nil.

Result depends on syntax table's string quote character."
  (nth 3 (syntax-ppss)))

(defvar literal-string--string-quote-regex "[^\\\\]\"")

(defun literal-string--at-quote? ()
  "True if point at at string quote."
  (save-excursion
    (backward-char 1)
    (looking-at-p literal-string--string-quote-regex)))

(defun literal-string--region ()
  "Return start and end markers of current literal string.

Returns `nil` if point is not at or in a string literal."
  (save-excursion
    (cond
     ((and (not (literal-string--inside-string?))
           (literal-string--at-quote?))
      ;; at start of quoted string
      (forward-char 1)
      (let ((start (point-marker)))
        (search-forward-regexp literal-string--string-quote-regex)
        (backward-char 1)
        (list start (point-marker))))
     ((and (literal-string--inside-string?)
           (not (literal-string--at-quote?)))
      ;; somewhere in quoted string
      (search-forward-regexp literal-string--string-quote-regex)
      (backward-char 1)
      (let ((end (point-marker)))
        (search-backward-regexp literal-string--string-quote-regex)
        (forward-char 2)
        (let ((start (point-marker)))
          (list start end))))
     ((and (literal-string--inside-string?)
           (literal-string--at-quote?))
      ;; at end of quoted string
      (let ((end (point-marker)))
        (search-backward-regexp literal-string--string-quote-regex)
        (forward-char 2)
        (list end (point-marker)))))))

(defun literal-string--docstring-indent-level ()
  "Find indent level of current buffer after first line."
  (save-excursion
    (goto-char (point-min))
    (forward-line 1)
    (let ((indent-count nil))
      (while (not (eobp))
        (when (not (looking-at "[[:space:]]*$"))
          (setq indent-count (if indent-count
                                 (min indent-count (current-indentation))
                               (current-indentation))))
        (forward-line 1))
      indent-count)))

(defun literal-string--docstring-deindent ()
  "Remove extraneous indentation of lines after the first one.

Returns the amount of indentation removed."
  (when-let (level (literal-string--docstring-indent-level))
    (when (not (zerop level))
      (indent-rigidly (point-min) (point-max) (- level))
      level)))

(defun literal-string--docstring-reindent (indent-level)
  "Re-indent literal string editing buffer.

Use INDENT-LEVEL provided by previous invocation of
`literal-string--docstring-deindent`."
  (when (and indent-level
             (not (zerop indent-level)))
    (save-excursion
      (goto-char (point-min))
      (forward-line)
      (when (not (eobp))
        (indent-rigidly (point) (point-max) indent-level)))))

(defun literal-string--replace-all (from to)
  "Replace all occurences of `FROM` to `TO` in buffer."
  (save-excursion
    (goto-char (point-min))
    (while (search-forward from (point-max) t)
      (save-match-data
        (replace-match to t t)))))

(defun literal-string--unescape ()
  "Unescape quotes and backslashes in buffer."
  (literal-string--replace-all "\\\"" "\"")
  (literal-string--replace-all "\\\\" "\\"))

(defun literal-string--escape ()
  "Escape quotes and backslashes in buffer."
  (literal-string--replace-all "\\" "\\\\")
  (literal-string--replace-all "\"" "\\\""))

(defgroup literal-string
  ()
  "Minor modes for editing string literals in source code."
  :group 'tools :group 'lisp)

(defcustom literal-string-fill-column 62
  "Fill column to use in the string editing buffer.
`nil` means do not set `fill-column`"
  :type 'integer
  :group 'literal-string)

(defcustom literal-string-editing-mode 'text-mode
  "The major mode to use in the string editing buffer."
  :type 'symbol
  :group 'literal-string)

(make-variable-buffer-local 'literal-string-editing-mode)

(defcustom literal-string-default-indent-level-alist
  '((clojure-mode . 2)
    (elisp-mode . 0))
  "Indentation level per mode.

This can be overridden by `literal-string-default-indent-level`."
  :type 'alist
  :group 'literal-string)

(defcustom literal-string-default-indent-level nil
  "The default indent level.

Will be used when committing multi-line strings.  Setting this
variable to non-nil overrides values defined in
`literal-string-default-indent-level-alist`.  Use 0 if you want
to force non-indenting behaviour.

This is intended to be used on a file-local or dir-local basis."
  :type 'sexp
  :group 'literal-string)

(make-variable-buffer-local 'literal-string-default-indent-level)

(defcustom literal-string-force-indent nil
  "When t, re-indent using the default indent level.

When nil, preserve previous indentation.  See
`literal-string-get-default-indent-level` on how to customize the
amount of indentation."
  :type 'boolean
  :group 'literal-string)

(make-variable-buffer-local 'literal-string-force-indent)

(defun literal-string-get-default-indent-level ()
  "Return the default indent level for docstrings buffer.

This gets its value from `literal-string-default-indent-level`, if
set, otherwise it will look up the source buffer's major mode in
`literal-string-default-indent-level-alist`."
  (or literal-string-default-indent-level
      (cdr (or (assoc major-mode literal-string-default-indent-level-alist)
               (assoc nil literal-string-default-indent-level-alist)))))

(defun literal-string--prepare-buffer (default-indent-level force-p)
  "Prepare the edit-indirect buffer for editing.

Unescapes characters and undoes additional indentation of
multi-line strings, registers a hook to restore them when
committing changes.

DEFAULT-INDENT-LEVEL specifies the number of spaces to use for
indentation.  When FORCE-P is `t`, use DEFAULT-INDENT-LEVEL always,
instead of using previous indentation."
  (literal-string--unescape)
  (let* ((previous-indent-level (literal-string--docstring-deindent))
         (indent-level (if force-p
                           default-indent-level
                         (or previous-indent-level default-indent-level))))
    (add-hook 'edit-indirect-before-commit-hook
              (lambda ()
                (literal-string--cleanup-region indent-level))
              t t)))

(defun literal-string--cleanup-region (indent-level)
  "Prepare edited string literal for re-insertion in source buffer.

Use INDENT-LEVEL provided by previous invocation of
`literal-string--docstring-deindent`."
  (save-match-data
    (literal-string--escape)
    (literal-string--docstring-reindent indent-level)))

;;;###autoload
(defun literal-string-edit-string ()
  "Edit current string literal in a separate buffer.

Uses `edit-indirect-mode`.  Use `edit-indirect-commit` to end
editing.

After committing the editing buffer, quotes and escape sequences
are correctly escaped and indentation of multi-line strings is
reinserted.

When a string was a single line (or blank) and is converted to a
multi-line paragraph, following lines are indented by the amount
specified by `literal-string-get-default-indent-level`.

Multi-line strings keep their earlier indentation level unless
`literal-string-force-indent` is set."
  (interactive)
  (require 'edit-indirect)
  (if-let (region (literal-string--region))
      (let ((mode literal-string-editing-mode) ;; buffer local, so get it out before switching
            (indent-level (literal-string-get-default-indent-level))
            (existing-buffer (edit-indirect--search-for-edit-indirect (car region) (cadr region)))
            (force-p literal-string-force-indent))
        (with-current-buffer (edit-indirect-region (car region) (cadr region) t)
          (when (null existing-buffer)
            (funcall mode)
            (literal-string--prepare-buffer indent-level force-p))))
    (user-error "Not at a string literal")))

(defvar literal-string-mode-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c \"") 'literal-string-edit-string)
    map))

;;;###autoload
(define-minor-mode literal-string-mode
  "A minor mode for editing literal (documentation) strings in
source code.

Provides support for editing strings, automatic (un)escaping of
quotes and docstring indentation."
  :lighter " str"
  :keymap literal-string-mode-keymap)

(provide 'literal-string)

;;; literal-string.el ends here
