;;; consult-dash.el --- Consult front-end for dash-docs  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Ravi R Kiran

;; Author: Ravi R Kiran <lists.ravi@gmail.com>
;; Keywords: consult, dash, docs
;; Created: 2022
;; Version: 0.5
;; Package-Requires: ((emacs "27.2") (dash-docs "1.4.0") (consult "0.16"))
;; URL: https://codeberg.org/ravi/consult-dash

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, version 3.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; consult-dash is the only interface function, a consult front-end
;; for dash-docs. Embark integration is automatically provided.

;;; To do

;; - Avoid concatenating commands through the shell

;;; Code:

(require 'cl-lib)
(require 'consult)
(require 'dash-docs)
(require 'subr-x)
(require 'thingatpt)

(defvar-local consult-dash-docsets nil
  "Docsets to use for this buffer.")
(defvar consult-dash-sqlite-args "sqlite3 -list"
  "Sqlite command line arguments.")

(defun consult-dash--add-docsets (old-fun &rest args)
  "Add docsets from variable `consult-dash-docsets' to search list.

OLD-FUN is the function that will be advised, normally
`dash-docs-buffer-local-docsets'.  ARGS are passed directly to
OLD-FUN."
  (let ((old (apply old-fun args)))
    (delq nil (delete-dups (append old consult-dash-docsets)))))
(advice-add #'dash-docs-buffer-local-docsets :around #'consult-dash--add-docsets)

(defvar consult-dash--history nil
  "Previous queries for dash docs via consult.")
(defvar consult-dash--docset-prefix "DOCSET:"
  "Prefix to identify docset boundaries.")

(defun consult-dash--builder-one-docset (docset pattern)
  "Build query to search for PATTERN in DOCSET."
  (let* ((query (dash-docs-sql-query (caddr docset)
                                     (dash-docs-sub-docset-name-in-pattern pattern
                                                                           (car docset))))
         (cmd (concat "echo " consult-dash--docset-prefix
                      (shell-quote-argument (car docset))
                      "; "
                      consult-dash-sqlite-args
                      " "
                      (shell-quote-argument (cadr docset))
                      " "
                      (shell-quote-argument query)
                      "; ")))
    cmd))

;; Is there a better way to run multiple commands when using consult--async-command?
(defun consult-dash--builder (input)
  "Build command line to search for INPUT."
  (pcase-let ((`(,arg . ,_) (consult--command-split input)))
    (unless (string-blank-p arg)
      (when-let* ((docsets (dash-docs-maybe-narrow-docsets arg))
                  (cmds (mapcar (lambda (ds) (consult-dash--builder-one-docset ds arg)) docsets)))
        (list :command (list "sh" "-c" (apply #'concat cmds))
              :highlight (cdr (consult--default-regexp-compiler arg 'basic t)))))))

(defun consult-dash--with-buffer-context (func)
  "Ensure that FUNC is called with the correct buffer context."
  (let ((buf (current-buffer)))
    (lambda (&rest args)
      (with-current-buffer buf
        (apply func args)))))

;; Emacs lisp is single-threaded, but passing around global variables
;; to maintain state (even within fake asynchronous code) requires
;; mental overhead to ensure that there are no inconsistencies.
;; Avoiding global variables (since gensym creates global variables)
;; requires a closure:
(defun consult-dash--local-variable (&optional value)
  "Closure representing a local variable with initial value VALUE.

To set a new value, call the closure with it as the argument.
To get the current value, call the closure with no arguments."
  (let ((var))
    (setq var value)
    (lambda (&rest val)
      (when val (setq var (car val)))
      var)))

(defun consult-dash--format (lines current-docset)
  "Format dash candidates from LINES.

Each line in LINES is of one of two forms:
  1. Variable `consult-dash--docset-prefix' followed by the actual docset name
  2. Query output from sqlite3
The first form indicates the docset from which subsequent results are returned.
Argument CURRENT-DOCSET is a closure used to maintain state across invocations."
  (let ((candidates)
        (current-candidate))
    (save-match-data
      (dolist (str lines)
        (setq current-candidate (split-string str "|" t))
        (if (= 1 (length current-candidate))
            ;; FIXME: If we do not find the right prefix, we should raise an error
            (when (string-prefix-p consult-dash--docset-prefix str)
              (funcall current-docset (substring str (length consult-dash--docset-prefix))))
          (let ((name (cadr current-candidate))
                (type (car current-candidate))
                (path (caddr current-candidate))
                (anchor (cadddr current-candidate)))
            (add-face-text-property 0 (length name) 'consult-key nil name)
            (put-text-property 0 (length name)
                               'consult-dash-docinfo
                               (list (funcall current-docset) type path anchor)
                               name)
            (push (list
                   name ;; replaces(format "%s (%s)" name type)
                   (funcall current-docset)
                   current-candidate)
                  candidates)))))
    (nreverse candidates)))

(defun consult-dash--make-formatter (current-docset-var)
  "Make formatter for a given state CURRENT-DOCSET-VAR."
  (lambda (lines) (consult-dash--format lines current-docset-var)))

(defun consult-dash--group (candidate transform)
  "Grouping function for CANDIDATE; used if TRANSFORM is nil."
  (if transform
      candidate
    (car (get-text-property 0 'consult-dash-docinfo candidate))))

(defun consult-dash--ellipsis ()
  "Backwards compatibility for `truncate-string-ellipsis'."
  (cond
   ((bound-and-true-p truncate-string-ellipsis))
   ((char-displayable-p ?…) "…")
   ("...")))

(defun consult-dash--annotate (candidate)
  "Format marginalia for CANDIDATE."
  (seq-let (docset-name type filename anchor) (get-text-property 0 'consult-dash-docinfo candidate)
    (when (and type filename docset-name)
      (concat "  " (truncate-string-to-width docset-name 12 0 ?\s (consult-dash--ellipsis) t)
              "  " (truncate-string-to-width type 12 0 ?\s (consult-dash--ellipsis) t)
              (format "%s%s" filename (if anchor (format "#%s" anchor) ""))))))

(defun consult-dash-candidate-url (candidate)
  "Return URL for CANDIDATE."
  (seq-let (docset-name _ filename anchor) (get-text-property 0 'consult-dash-docinfo candidate)
    (dash-docs-result-url docset-name filename anchor)))

(defun consult-dash-yank-candidate-url (candidate)
  "Copy URL for CANDIDATE to the kill ring."
  (if-let (url (consult-dash-candidate-url candidate))
      (kill-new url)
    (message "No URL for this candidate")))

(defun consult-dash--open-url (candidate)
  "Open URL for CANDIDATE in browser.  See `dash-docs-browser-func'."
  (seq-let (docset-name _ filename anchor) (get-text-property 0 'consult-dash-docinfo candidate)
    (funcall dash-docs-browser-func (dash-docs-result-url docset-name filename anchor))))

;;;###autoload
(defun consult-dash (&optional initial)
  "Consult interface for dash documentation.

INITIAL is the default value provided."
  (interactive)
  (dash-docs-create-common-connections)
  (dash-docs-create-buffer-connections)
  (let ((builder (consult-dash--with-buffer-context #'consult-dash--builder))
        (current-docset (consult-dash--local-variable)))
    ;; Can we replace cl-flet here with something not in cl-lib?
    (cl-flet ((formatter-fn (consult-dash--make-formatter current-docset)))
      (when-let ((search-result (consult--read
                                 (consult--async-command builder
                                   (consult--async-transform formatter-fn)
                                   (consult--async-highlight builder))
                                 :prompt "Dash: "
                                 :require-match t
                                 :group #'consult-dash--group
                                 :lookup #'consult--lookup-cdr
                                 :category 'consult-dash-result
                                 :annotate #'consult-dash--annotate
                                 :initial (consult--async-split-initial initial)
                                 :add-history (consult--async-split-thingatpt 'symbol)
                                 :history '(:input consult-dash--history))))
        (dash-docs-browse-url search-result)))))

;; Embark integration
(defvar consult-dash-embark-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map "y" #'consult-dash-yank-candidate-url)
    map)
  "Actions for consult dash results.")
(eval-when-compile
  (defvar embark-general-map)
  (defvar embark-keymap-alist)
  (defvar embark-default-action-overrides))
(with-eval-after-load 'embark
  (setq consult-dash-embark-keymap
        (make-composed-keymap consult-dash-embark-keymap embark-general-map))
  (add-to-list 'embark-keymap-alist
               '(consult-dash-result . consult-dash-embark-keymap))
  (setf (alist-get 'consult-dash-result embark-default-action-overrides)
        #'consult-dash--open-url))

(provide 'consult-dash)
;;; consult-dash.el ends here
